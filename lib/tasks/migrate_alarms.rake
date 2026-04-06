namespace :alarms do
  desc "Migrate AlertThreshold records to Alarm records with auto-generated AlarmActions"
  task migrate_thresholds: :environment do
    COMPARISON_MAP = {
      "gt" => "GreaterThanThreshold",
      "gte" => "GreaterThanOrEqualToThreshold",
      "lt" => "LessThanThreshold",
      "lte" => "LessThanOrEqualToThreshold"
    }.freeze

    PARAMETER_TO_METRIC = {
      "precipitation" => "precipitation_3h",
      "precipitation_1h" => "precipitation_1h",
      "precipitation_3h" => "precipitation_3h",
      "river_level" => "river_level"
    }.freeze

    THRESHOLD_TYPE_TO_PERIOD = {
      "accumulated_1h" => 3600,
      "accumulated_3h" => 10_800,
      "instant" => 300
    }.freeze

    STATISTIC_FOR_METRIC = {
      "precipitation_1h" => "Sum",
      "precipitation_3h" => "Sum",
      "river_level" => "Maximum"
    }.freeze

    migrated = 0
    skipped = 0

    AlertThreshold.find_each do |threshold|
      metric_name = PARAMETER_TO_METRIC[threshold.parameter]
      unless metric_name
        puts "  SKIP: unknown parameter '#{threshold.parameter}' (threshold ##{threshold.id})"
        skipped += 1
        next
      end

      alarm = Alarm.find_or_initialize_by(
        alarm_type: "metric",
        metric_name: metric_name,
        river_basin: threshold.river_basin,
        river: threshold.river,
        severity: threshold.severity
      )

      alarm.assign_attributes(
        name: build_alarm_name(threshold, metric_name),
        statistic: STATISTIC_FOR_METRIC[metric_name] || "Sum",
        period_seconds: THRESHOLD_TYPE_TO_PERIOD[threshold.threshold_type] || 3600,
        evaluation_periods: 1,
        datapoints_to_alarm: 1,
        comparison_operator: COMPARISON_MAP[threshold.comparison],
        threshold_value: threshold.value,
        unit: threshold.unit,
        missing_data_treatment: "missing",
        enabled: threshold.active,
        state: "insufficient_data"
      )

      if alarm.save
        create_actions_for(alarm, threshold.severity)
        migrated += 1
        puts "  OK: #{alarm.name} (severity #{alarm.severity})"
      else
        puts "  ERROR: #{alarm.errors.full_messages.join(', ')} (threshold ##{threshold.id})"
        skipped += 1
      end
    end

    puts "\nMigration complete: #{migrated} migrated, #{skipped} skipped"
  end
end

def build_alarm_name(threshold, metric_name)
  scope = if threshold.river_basin
    threshold.river_basin.name
  elsif threshold.river
    threshold.river.name
  else
    "Global"
  end

  type_label = case metric_name
  when "precipitation_1h" then "Precipitação 1h"
  when "precipitation_3h" then "Precipitação 3h"
  when "river_level" then "Nível do rio"
  else metric_name
  end

  "#{type_label} — #{scope} (sev #{threshold.severity})"
end

def create_actions_for(alarm, severity)
  return if alarm.alarm_actions.for_state("alarm").enabled.exists?

  channels = AlertNotifier::SEVERITY_CHANNELS.fetch(severity, %w[websocket])

  alarm.alarm_actions.create!(
    trigger_state: "alarm",
    action_type: "notification",
    configuration: { "channels" => channels },
    enabled: true
  )

  # Always notify on recovery via websocket
  alarm.alarm_actions.find_or_create_by!(trigger_state: "ok", action_type: "notification") do |a|
    a.configuration = { "channels" => %w[websocket] }
    a.enabled = true
  end
end
