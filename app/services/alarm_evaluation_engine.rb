class AlarmEvaluationEngine
  def self.evaluate_all
    Alarm.enabled.metric_alarms.find_each { |alarm| evaluate_alarm(alarm) }
  end

  def self.evaluate_alarm(alarm)
    new(alarm).evaluate
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def evaluate
    datapoints = collect_period_datapoints
    new_state, new_severity = determine_state(datapoints)

    @alarm.update!(
      last_evaluated_at: Time.current,
      last_datapoints: datapoints
    )

    @alarm.transition_to!(
      new_state,
      reason: build_reason(datapoints, new_state, new_severity),
      datapoints: datapoints,
      severity: new_severity
    )
  end

  private

  # forecast_precip looks ahead instead of back — "period 1" is the soonest upcoming
  # window, not the most recent past one — since a forecast alarm promises to catch
  # what's coming, not what already happened (see MetricDataCollector#collect_forecast_precip,
  # which has no way to express "the last N hours" for data that's inherently about the
  # future). Every other metric keeps the existing look-back behavior.
  def collect_period_datapoints
    now = Time.current
    periods = @alarm.evaluation_periods
    period_length = @alarm.period_seconds.seconds
    forecast = @alarm.metric_name == "forecast_precip"

    (0...periods).map do |i|
      if forecast
        period_start = now + (i * period_length)
        period_end = period_start + period_length
      else
        period_end = now - (i * period_length)
        period_start = period_end - period_length
      end

      value = MetricDataCollector.collect(
        metric_name: @alarm.metric_name,
        river_basin: @alarm.river_basin,
        monitoring_stations: Array(@alarm.monitoring_station),
        forecast_source: @alarm.forecast_source,
        period_start: period_start,
        period_end: period_end,
        statistic: @alarm.statistic
      )

      breaching_severity = value.nil? ? nil : evaluate_threshold_bands(value)
      { "period" => i + 1, "value" => value, "breaching_severity" => breaching_severity }
    end
  end

  # Returns the highest severity whose threshold is breached, or 0 if none.
  def evaluate_threshold_bands(value)
    @alarm.alarm_thresholds.order(severity: :desc).each do |threshold|
      return threshold.severity if threshold_breached?(value, threshold)
    end
    0
  end

  def threshold_breached?(value, threshold)
    case threshold.comparison_operator
    when "GreaterThanThreshold"           then value > threshold.threshold_value
    when "GreaterThanOrEqualToThreshold"  then value >= threshold.threshold_value
    when "LessThanThreshold"             then value < threshold.threshold_value
    when "LessThanOrEqualToThreshold"    then value <= threshold.threshold_value
    else false
    end
  end

  # Returns [new_state, severity] tuple.
  def determine_state(datapoints)
    missing_count = datapoints.count { |dp| dp["breaching_severity"].nil? }
    total = datapoints.size

    return ["insufficient_data", nil] if missing_count == total

    # Find the highest severity with enough breaching periods. Missing periods
    # never count as breaching — an outage should never look like a worsening
    # reading.
    [4, 3, 2, 1].each do |sev|
      effective_breaching = datapoints.count { |dp| dp["breaching_severity"] && dp["breaching_severity"] >= sev }
      return ["alarm", sev] if effective_breaching >= @alarm.datapoints_to_alarm
    end

    ["ok", nil]
  end

  def build_reason(datapoints, new_state, severity)
    values = datapoints.filter_map { |dp| dp["value"] }
    breaching_count = datapoints.count { |dp| dp["breaching_severity"].to_i >= 1 }
    missing_count   = datapoints.count { |dp| dp["breaching_severity"].nil? }

    case new_state
    when "alarm"
      band = @alarm.alarm_thresholds.find_by(severity: severity)
      threshold_desc = band ? "#{band.threshold_value}#{band.unit} (severity #{severity})" : "severity #{severity}"
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold #{threshold_desc} (values: #{values.map { |v| v&.round(2) }})"
    when "ok"
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold (below #{@alarm.datapoints_to_alarm} required)"
    when "insufficient_data"
      "#{missing_count} of #{@alarm.evaluation_periods} evaluation periods had no data"
    end
  end
end
