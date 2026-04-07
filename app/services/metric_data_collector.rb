class MetricDataCollector
  SEARCH_RADIUS_M = 5000

  def self.collect(metric_name:, river_basin:, river: nil, period_start:, period_end:, statistic: nil)
    new(river_basin: river_basin, river: river).collect(metric_name, period_start, period_end, statistic)
  end

  def initialize(river_basin:, river: nil)
    @river_basin = river_basin
    @river = river
  end

  def collect(metric_name, period_start, period_end, statistic = nil)
    case metric_name
    when "precipitation_1h", "precipitation_3h"
      collect_precipitation(period_start, period_end, statistic)
    when "river_level"
      collect_river_level(period_start, period_end, statistic)
    when "risk_score"
      collect_risk_score(period_start, period_end, statistic)
    when "soil_moisture"
      collect_soil_moisture(period_start, period_end)
    when "forecast_precip"
      collect_forecast_precip(period_start, period_end)
    end
  end

  private

  def collect_precipitation(period_start, period_end, statistic)
    sensor_ids = pluviometer_ids
    return 0.0 if sensor_ids.empty?

    readings = SensorReading.where(sensor_id: sensor_ids)
                            .by_type("precipitation")
                            .where(recorded_at: period_start..period_end)

    apply_statistic(readings, statistic || "Sum")
  end

  def collect_river_level(period_start, period_end, statistic)
    return nil unless @river

    gauge_ids = Sensor.joins(:monitoring_station)
                      .where(monitoring_stations: { river_id: @river.id })
                      .where(sensor_type: :river_gauge, status: :active)
                      .pluck(:id)
    return nil if gauge_ids.empty?

    readings = SensorReading.where(sensor_id: gauge_ids)
                            .by_type("river_level")
                            .where(recorded_at: period_start..period_end)

    return nil if readings.none?

    stat = statistic || "Maximum"
    case stat
    when "Maximum" then readings.maximum(:value)
    when "Minimum" then readings.minimum(:value)
    when "Average" then readings.average(:value)&.to_f
    else
      readings.order(recorded_at: :desc).first&.value
    end
  end

  def collect_risk_score(period_start, period_end, statistic)
    assessments = RiskAssessment.where(river_basin: @river_basin)
                                .where(assessed_at: period_start..period_end)
    return nil if assessments.none?

    case statistic || "Maximum"
    when "Maximum" then assessments.maximum(:risk_score)
    when "Minimum" then assessments.minimum(:risk_score)
    when "Average" then assessments.average(:risk_score)&.to_f
    else assessments.order(assessed_at: :desc).first&.risk_score
    end
  end

  def collect_soil_moisture(period_start, period_end)
    forecast = WeatherForecast.by_source("open_meteo")
                              .where(valid_from: period_start..period_end)
                              .order(issued_at: :desc)
                              .first
    raw = forecast&.raw_data || {}
    if raw.key?("soil_moisture_avg")
      return raw["soil_moisture_avg"].to_f
    end

    # Fallback: 72h accumulated precipitation / 100
    sensor_ids = pluviometer_ids
    return nil if sensor_ids.empty?

    precip = SensorReading.where(sensor_id: sensor_ids)
                          .by_type("precipitation")
                          .since(72.hours.ago)
                          .sum(:value)
    (precip / 100.0).clamp(0.0, 1.0)
  end

  def collect_forecast_precip(period_start, period_end)
    forecasts = WeatherForecast.where(valid_from: period_start..period_end)
    return nil if forecasts.none?

    forecasts.maximum(:precipitation_mm)
  end

  def apply_statistic(readings, statistic)
    case statistic
    when "Sum" then readings.sum(:value)
    when "Average" then readings.average(:value)&.to_f || 0.0
    when "Maximum" then readings.maximum(:value) || 0.0
    when "Minimum" then readings.minimum(:value) || 0.0
    when "SampleCount" then readings.count.to_f
    else readings.sum(:value)
    end
  end

  def pluviometer_ids
    @pluviometer_ids ||= begin
      if @river_basin.geometry
        ids = Sensor.joins(:monitoring_station)
                    .where(sensor_type: :pluviometer, status: :active)
                    .where("ST_DWithin(monitoring_stations.location::geography, ?::geography, ?)", @river_basin.geometry, SEARCH_RADIUS_M)
                    .pluck(:id)
        return ids if ids.any?
      end

      Sensor.joins(:monitoring_station)
            .where(sensor_type: :pluviometer, status: :active)
            .where(monitoring_stations: { river_basin_id: @river_basin.id })
            .pluck(:id)
    rescue ActiveRecord::StatementInvalid
      []
    end
  end
end
