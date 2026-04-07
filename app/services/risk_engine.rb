class RiskEngine
  WEIGHTS = {
    precipitation: 0.35,
    river_level: 0.25,
    forecast: 0.25,
    soil_moisture: 0.15
  }.freeze

  PRECIPITATION_THRESHOLDS_1H = [10.0, 25.0, 50.0].freeze
  FORECAST_REFERENCE_MM = 50.0
  SEARCH_RADIUS_M = 5000

  attr_reader :river_basin

  def initialize(river_basin)
    @river_basin = river_basin
  end

  def self.assess(river_basin)
    new(river_basin).assess
  end

  def self.assess_all
    RiverBasin.active.find_each { |basin| assess(basin) }
  end

  def assess
    scores = {
      precipitation: compute_precipitation_score,
      river_level: compute_river_level_score,
      forecast: compute_forecast_score,
      soil_moisture: compute_soil_moisture_score
    }

    weighted_score = scores.sum { |k, v| WEIGHTS[k] * v }.round(4)
    weighted_score = weighted_score.clamp(0.0, 1.0)
    level = score_to_level(weighted_score)

    assessment = create_assessment(scores, weighted_score, level)
    update_river_basin(weighted_score, level, scores)
    assessment
  end

  private

  def compute_precipitation_score
    sensor_ids = nearby_sensor_ids(:pluviometer)
    return 0.0 if sensor_ids.empty?

    readings = SensorReading.where(sensor_id: sensor_ids)
                            .by_type("precipitation")

    precip_1h = readings.since(1.hour.ago).sum(:value)
    precip_3h = readings.since(3.hours.ago).sum(:value)
    precip_6h = readings.since(6.hours.ago).sum(:value)

    score_1h = normalize_precipitation(precip_1h, PRECIPITATION_THRESHOLDS_1H)
    score_3h = normalize_precipitation(precip_3h, [20.0, 40.0, 80.0])
    score_6h = normalize_precipitation(precip_6h, [30.0, 60.0, 120.0])

    # Heavier weight on shorter windows
    ((score_1h * 0.5) + (score_3h * 0.3) + (score_6h * 0.2)).clamp(0.0, 1.0)
  end

  def compute_river_level_score
    rivers = nearby_rivers
    return 0.0 if rivers.empty?

    scores = rivers.filter_map do |river|
      gauge_ids = Sensor.joins(:monitoring_station)
                        .where(monitoring_stations: { river_id: river.id })
                        .where(sensor_type: :river_gauge, status: :active)
                        .pluck(:id)
      next if gauge_ids.empty?

      latest = SensorReading.where(sensor_id: gauge_ids)
                            .by_type("river_level")
                            .recent
                            .first
      next unless latest

      interpolate_river_level(latest.value, river)
    end

    scores.any? ? scores.max : 0.0
  end

  def compute_forecast_score
    forecasts = WeatherForecast.valid_in_next(6.hours)
    return 0.0 if forecasts.empty?

    scores = forecasts.map do |f|
      precip_factor = (f.precipitation_mm.to_f / FORECAST_REFERENCE_MM).clamp(0.0, 1.0)
      prob_factor = (f.precipitation_probability.to_f / 100.0).clamp(0.0, 1.0)
      precip_factor * prob_factor
    end

    scores.max.clamp(0.0, 1.0)
  end

  def compute_soil_moisture_score
    # Try Open-Meteo soil moisture from forecast raw_data
    forecast = WeatherForecast.by_source("open_meteo").current.order(issued_at: :desc).first
    raw = forecast&.raw_data
    raw = JSON.parse(raw) if raw.is_a?(String) rescue nil
    if raw.is_a?(Hash) && raw.key?("soil_moisture_avg")
      moisture = raw["soil_moisture_avg"].to_f
      # Soil moisture 0.0-0.5 m³/m³ → normalized score
      return (moisture / 0.45).clamp(0.0, 1.0)
    end

    # Fallback: estimate from 72h accumulated precipitation
    sensor_ids = nearby_sensor_ids(:pluviometer)
    return 0.0 if sensor_ids.empty?

    precip_72h = SensorReading.where(sensor_id: sensor_ids)
                              .by_type("precipitation")
                              .since(72.hours.ago)
                              .sum(:value)

    # 100mm over 72h → fully saturated
    (precip_72h / 100.0).clamp(0.0, 1.0)
  end

  def normalize_precipitation(value, thresholds)
    low, moderate, high = thresholds
    if value >= high
      1.0
    elsif value >= moderate
      0.6 + 0.4 * ((value - moderate) / (high - moderate))
    elsif value >= low
      0.3 + 0.3 * ((value - low) / (moderate - low))
    elsif value > 0
      0.3 * (value / low)
    else
      0.0
    end
  end

  def interpolate_river_level(current_level, river)
    normal = river.normal_level_m || 0.0
    alert = river.alert_level_m || normal
    flood = river.flood_level_m || alert
    overflow = river.overflow_level_m || flood

    if current_level >= overflow
      1.0
    elsif current_level >= flood
      0.8 + 0.2 * ((current_level - flood) / (overflow - flood))
    elsif current_level >= alert
      0.6 + 0.2 * ((current_level - alert) / (flood - alert))
    elsif current_level >= normal
      0.1 + 0.5 * ((current_level - normal) / (alert - normal))
    else
      0.0
    end
  end

  def score_to_level(score)
    case score
    when 0.0...0.2 then 0
    when 0.2...0.4 then 1
    when 0.4...0.6 then 2
    when 0.6...0.8 then 3
    else 4
    end
  end

  def create_assessment(scores, weighted_score, level)
    RiskAssessment.create!(
      river_basin: river_basin,
      assessed_at: Time.current,
      risk_level: level,
      risk_score: weighted_score,
      precipitation_score: scores[:precipitation],
      river_level_score: scores[:river_level],
      forecast_score: scores[:forecast],
      soil_moisture_score: scores[:soil_moisture],
      contributing_factors: scores.transform_values { |v| v.round(4) },
      sensor_data_snapshot: build_snapshot
    )
  end

  def update_river_basin(weighted_score, level, scores)
    river_basin.update!(
      current_risk_level: level,
      current_risk_score: weighted_score,
      risk_factors: scores.transform_values { |v| v.round(4) },
      risk_updated_at: Time.current
    )
  end

  def build_snapshot
    {
      assessed_at: Time.current.iso8601,
      river_basin_id: river_basin.id
    }
  end

  def nearby_sensor_ids(sensor_type)
    return Sensor.nearby_pluviometers(river_basin).pluck(:id) if sensor_type.to_sym == :pluviometer

    return [] unless river_basin.geometry

    Sensor.joins(:monitoring_station)
          .where(sensor_type: sensor_type, status: :active)
          .where("ST_DWithin(monitoring_stations.location::geography, ?::geography, ?)", river_basin.geometry, SEARCH_RADIUS_M)
          .pluck(:id)
  rescue ActiveRecord::StatementInvalid
    []
  end

  def nearby_rivers
    river_basin.rivers
  end
end
