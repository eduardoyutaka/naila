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
    alerts = []

    thresholds = applicable_thresholds
    thresholds.each do |threshold|
      next unless threshold_breached?(threshold)
      next if cooldown_active?(threshold)

      alert = create_alert(threshold)
      alerts << alert if alert
    end

    alerts
  end

  private

  def applicable_thresholds
    basin_thresholds = AlertThreshold.active.where(river_basin: @river_basin)
    river_thresholds = AlertThreshold.active.where(river: rivers)
    global_thresholds = AlertThreshold.active.where(river_basin: nil, river: nil)

    (basin_thresholds + river_thresholds + global_thresholds).uniq
  end

  def threshold_breached?(threshold)
    current_value = current_value_for(threshold)
    return false unless current_value

    case threshold.comparison
    when "gt" then current_value > threshold.value
    when "gte" then current_value >= threshold.value
    when "lt" then current_value < threshold.value
    when "lte" then current_value <= threshold.value
    else false
    end
  end

  def current_value_for(threshold)
    case threshold.parameter
    when "precipitation", "precipitation_1h"
      if threshold.threshold_type&.include?("3h")
        precipitation_3h
      else
        precipitation_1h
      end
    when "precipitation_3h"
      precipitation_3h
    when "river_level"
      latest_river_level(threshold.river)
    else
      nil
    end
  end

  def precipitation_1h
    @precipitation_1h ||= begin
      station_ids = nearby_pluviometer_ids
      return 0.0 if station_ids.empty?

      SensorReading.where(sensor_station_id: station_ids)
                   .by_type("precipitation")
                   .since(1.hour.ago)
                   .sum(:value)
    end
  end

  def precipitation_3h
    @precipitation_3h ||= begin
      station_ids = nearby_pluviometer_ids
      return 0.0 if station_ids.empty?

      SensorReading.where(sensor_station_id: station_ids)
                   .by_type("precipitation")
                   .since(3.hours.ago)
                   .sum(:value)
    end
  end

  def latest_river_level(river)
    return nil unless river

    gauge_ids = river.sensor_stations.where(station_type: :river_gauge, status: :active).pluck(:id)
    return nil if gauge_ids.empty?

    SensorReading.where(sensor_station_id: gauge_ids)
                 .by_type("river_level")
                 .recent
                 .first
                 &.value
  end

  def cooldown_active?(threshold)
    Alert.where(alert_threshold: threshold, river_basin: @river_basin)
         .where(status: %w[active acknowledged])
         .where("created_at > ?", threshold.cooldown_minutes.minutes.ago)
         .exists?
  end

  def create_alert(threshold)
    river = threshold.river
    current_val = current_value_for(threshold)

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
        ids = SensorStation.where(station_type: :pluviometer, status: :active)
                           .where("ST_DWithin(location::geography, ?::geography, 5000)", @river_basin.geometry)
                           .pluck(:id)
        return ids if ids.any?
      end

      # Fallback: match by river basin
      scope = SensorStation.where(station_type: :pluviometer, status: :active)
      scope.where(river_basin_id: @river_basin.id).pluck(:id)
    rescue ActiveRecord::StatementInvalid
      []
    end
  end

  def rivers
    @rivers ||= @river_basin.rivers
  end
end
