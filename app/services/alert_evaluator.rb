class AlertEvaluator
  PARAMETER_TITLES = {
    "precipitation" => "Precipitação acima do limiar",
    "river_level" => "Nível do rio acima do limiar de alerta"
  }.freeze

  PARAMETER_DESCRIPTIONS = {
    "precipitation" => "Acúmulo pluviométrico excedeu o limiar configurado na bacia %{basin}.",
    "river_level" => "Nível do rio %{river} atingiu %{value}%{unit}, acima do limiar de %{threshold}%{unit}."
  }.freeze

  def self.evaluate(risk_assessment)
    new(risk_assessment).evaluate
  end

  def initialize(risk_assessment)
    @assessment = risk_assessment
    @river_basin = risk_assessment.river_basin
  end

  def evaluate
    results = []

    group_thresholds(applicable_thresholds).each do |group_key, thresholds|
      _parameter, _threshold_type, _basin_id, river_id = group_key

      breached = thresholds.select { |t| threshold_breached?(t) }.sort_by(&:severity)
      highest_breached = breached.last

      existing = find_existing_alert(group_key)

      if highest_breached
        current_val = current_value_for(highest_breached)

        if existing
          if existing.severity != highest_breached.severity
            from_severity = existing.severity
            existing.update_severity!(highest_breached.severity, highest_breached, current_value: current_val, risk_assessment: @assessment)
            results << { alert: existing, action: :updated, from_severity: from_severity }
          end
          # severity unchanged — no action
        else
          next if recently_resolved?(group_key, thresholds)

          alert = create_alert(highest_breached, current_val)
          results << { alert: alert, action: :created }
        end
      elsif existing
        from_severity = existing.severity
        existing.resolve!
        results << { alert: existing, action: :resolved, from_severity: from_severity }
      end
    end

    results
  end

  private

  def applicable_thresholds
    basin_thresholds = AlertThreshold.active.where(river_basin: @river_basin)
    river_thresholds = AlertThreshold.active.where(river: rivers)
    global_thresholds = AlertThreshold.active.where(river_basin: nil, river: nil)

    (basin_thresholds + river_thresholds + global_thresholds).uniq
  end

  def group_thresholds(thresholds)
    thresholds.group_by { |t| [ t.parameter, t.threshold_type, @river_basin.id, t.river_id ] }
  end

  def find_existing_alert(group_key)
    parameter, threshold_type, _basin_id, river_id = group_key

    Alert.automatic_active
         .joins(:alert_threshold)
         .where(river_basin: @river_basin, river_id: river_id)
         .where(alert_thresholds: { parameter: parameter, threshold_type: threshold_type })
         .order(severity: :desc)
         .first
  end

  def recently_resolved?(group_key, thresholds)
    parameter, threshold_type, _basin_id, river_id = group_key
    max_cooldown = thresholds.map(&:cooldown_minutes).max

    Alert.where(alert_type: "automatic", status: "resolved")
         .where(river_basin: @river_basin, river_id: river_id)
         .joins(:alert_threshold)
         .where(alert_thresholds: { parameter: parameter, threshold_type: threshold_type })
         .where("alerts.resolved_at > ?", max_cooldown.minutes.ago)
         .exists?
  end

  def threshold_breached?(threshold)
    current_value = current_value_for(threshold)
    return false unless current_value

    case threshold.comparison
    when "gt"  then current_value > threshold.value
    when "gte" then current_value >= threshold.value
    when "lt"  then current_value < threshold.value
    when "lte" then current_value <= threshold.value
    else false
    end
  end

  def current_value_for(threshold)
    case threshold.parameter
    when "precipitation", "precipitation_1h"
      threshold.threshold_type&.include?("3h") ? precipitation_3h : precipitation_1h
    when "precipitation_3h"
      precipitation_3h
    when "river_level"
      latest_river_level(threshold.river)
    end
  end

  def precipitation_1h
    @precipitation_1h ||= begin
      sensor_ids = nearby_pluviometer_ids
      return 0.0 if sensor_ids.empty?

      SensorReading.where(sensor_id: sensor_ids)
                   .by_type("precipitation")
                   .since(1.hour.ago)
                   .sum(:value)
    end
  end

  def precipitation_3h
    @precipitation_3h ||= begin
      sensor_ids = nearby_pluviometer_ids
      return 0.0 if sensor_ids.empty?

      SensorReading.where(sensor_id: sensor_ids)
                   .by_type("precipitation")
                   .since(3.hours.ago)
                   .sum(:value)
    end
  end

  def latest_river_level(river)
    return nil unless river

    gauge_ids = Sensor.joins(:sensor_station)
                      .where(sensor_stations: { river_id: river.id })
                      .where(sensor_type: :river_gauge, status: :active)
                      .pluck(:id)
    return nil if gauge_ids.empty?

    SensorReading.where(sensor_id: gauge_ids)
                 .by_type("river_level")
                 .recent
                 .first
                 &.value
  end

  def create_alert(threshold, current_val = nil)
    current_val ||= current_value_for(threshold)
    river = threshold.river

    title = PARAMETER_TITLES[threshold.parameter] ||
            "Limiar de #{threshold.parameter} excedido"

    description = build_description(threshold, river, current_val)

    Alert.create!(
      title: title,
      description: description,
      severity: threshold.severity,
      alert_type: "automatic",
      status: "active",
      activated_at: Time.current,
      river_basin: @river_basin,
      river: river,
      alert_threshold: threshold,
      affected_area: @river_basin.geometry,
      trigger_data: {
        threshold_id: threshold.id,
        threshold_value: threshold.value,
        current_value: current_val,
        risk_score: @assessment.risk_score,
        risk_level: @assessment.risk_level,
        parameter: threshold.parameter,
        assessed_at: @assessment.assessed_at.iso8601
      }
    )
  end

  def build_description(threshold, river, current_val)
    template = PARAMETER_DESCRIPTIONS[threshold.parameter] ||
               "Parâmetro %{parameter} excedeu o limiar de %{threshold}%{unit}."

    format(template,
      basin: @river_basin.name,
      river: river&.name || "N/A",
      value: current_val&.round(1),
      threshold: threshold.value,
      unit: threshold.unit,
      parameter: threshold.parameter
    )
  end

  def nearby_pluviometer_ids
    @nearby_pluviometer_ids ||= begin
      if @river_basin.geometry
        ids = Sensor.joins(:sensor_station)
                    .where(sensor_type: :pluviometer, status: :active)
                    .where("ST_DWithin(sensor_stations.location::geography, ?::geography, 5000)", @river_basin.geometry)
                    .pluck(:id)
        return ids if ids.any?
      end

      Sensor.joins(:sensor_station)
            .where(sensor_type: :pluviometer, status: :active)
            .where(sensor_stations: { river_basin_id: @river_basin.id })
            .pluck(:id)
    rescue ActiveRecord::StatementInvalid
      []
    end
  end

  def rivers
    @rivers ||= @river_basin.rivers
  end
end
