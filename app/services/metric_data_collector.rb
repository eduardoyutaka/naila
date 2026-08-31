class MetricDataCollector
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

  # Like history_series, but bucketed over an explicit [from, to] range instead of a
  # fixed period count walked back from now — for a user-picked chart window. Bucket
  # size is never finer than the alarm's own period_seconds (no fabricated resolution)
  # and coarsens automatically once the range would otherwise exceed max_points buckets,
  # so a wide range doesn't render hundreds of bars.
  def self.history_series_for_range(alarm:, from:, to:, max_points: 96)
    bucket_seconds = [ alarm.period_seconds, ((to - from) / max_points).ceil ].max
    periods = ((to - from) / bucket_seconds).ceil
    collector = new(river_basin: alarm.river_basin, river: alarm.river)

    (0...periods).map { |i|
      period_end = [ to - (i * bucket_seconds), from ].max
      value = collector.collect(alarm.metric_name, period_end - bucket_seconds, period_end, alarm.statistic)
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
    sensors = @river_basin.configured_sensors.sensor_type_pluviometer.status_active
    return nil if sensors.none?

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

  # nil means "no data" (not "confirmed zero") for every statistic except
  # SampleCount, where a count of 0 readings is itself a real, meaningful
  # answer — AlarmEvaluationEngine relies on this nil to trigger
  # missing_data_treatment instead of silently evaluating "0mm, all clear".
  def apply_statistic(readings, statistic)
    return readings.count.to_f if statistic == "SampleCount"
    return nil unless readings.exists?

    case statistic
    when "Sum" then readings.sum(:value)
    when "Average" then readings.average(:value).to_f
    when "Maximum" then readings.maximum(:value)
    when "Minimum" then readings.minimum(:value)
    else readings.sum(:value)
    end
  end

end
