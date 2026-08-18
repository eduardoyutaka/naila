class MetricDataCollector
  SEARCH_RADIUS_M = 5000

  # Single source of truth for which metric_name values are actually wired up —
  # drives the alarm form's dropdown (see admin/alarms/_form.html.erb) and
  # Alarm#metric_name's inclusion validation, so the two can't drift apart.
  SUPPORTED_METRICS = %w[precipitation forecast_precip].freeze

  def self.collect(metric_name:, river_basin:, river: nil, period_start:, period_end:, statistic: nil)
    new(river_basin: river_basin, river: river).collect(metric_name, period_start, period_end, statistic)
  end

  def self.history_series(alarm:, periods:)
    now = Time.current
    length = alarm.period_seconds.seconds
    collector = new(river_basin: alarm.river_basin, river: alarm.river)

    (0...periods).map { |i|
      period_end = now - (i * length)
      value = collector.collect(alarm.metric_name, period_end - length, period_end, alarm.statistic)
      { period_end: period_end, value: value }
    }.reverse
  end

  def initialize(river_basin:, river: nil)
    @river_basin = river_basin
    @river = river
  end

  def collect(metric_name, period_start, period_end, statistic = nil)
    case metric_name
    when "precipitation"
      collect_precipitation(period_start, period_end, statistic)
    when "forecast_precip"
      collect_forecast_precip(period_start, period_end)
    end
  end

  private

  def collect_precipitation(period_start, period_end, statistic)
    sensors = Sensor.nearby_pluviometers(@river_basin)
    return 0.0 if sensors.none?

    readings = SensorReading.where(sensor_id: sensors)
                            .by_type("precipitation")
                            .where(recorded_at: period_start..period_end)

    apply_statistic(readings, statistic || "Sum")
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

end
