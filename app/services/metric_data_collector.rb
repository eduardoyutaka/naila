class MetricDataCollector
  # Single source of truth for which metric_name values are actually wired up —
  # drives the alarm form's dropdown (see admin/alarms/_form.html.erb) and
  # Alarm#metric_name's inclusion validation, so the two can't drift apart.
  SUPPORTED_METRICS = %w[precipitation forecast_precip].freeze

  def self.collect(metric_name:, river_basin:, monitoring_stations: nil, river: nil, forecast_source: nil, period_start:, period_end:, statistic: nil)
    new(river_basin: river_basin, monitoring_stations: monitoring_stations, river: river, forecast_source: forecast_source)
      .collect(metric_name, period_start, period_end, statistic)
  end

  def self.history_series(alarm:, periods:)
    now = Time.current
    length = alarm.period_seconds.seconds
    collector = new(river_basin: alarm.river_basin, monitoring_stations: Array(alarm.monitoring_station),
                     river: alarm.river, forecast_source: alarm.forecast_source)

    (0...periods).map { |i|
      period_end = now - (i * length)
      value = collector.collect(alarm.metric_name, period_end - length, period_end, alarm.statistic)
      { period_end: period_end, value: value }
    }.reverse
  end

  # Like history_series, but bucketed over an explicit [from, to] range instead of a
  # fixed period count walked back from now — for a user-picked chart window.
  #
  # Each point is a rolling accumulation over the alarm's own period_seconds (the same
  # window the alarm itself evaluates), sampled every `step_seconds` — decoupled from
  # period_seconds so a long-period alarm (e.g. a 24h rolling precipitation sum) still
  # renders several overlapping points instead of collapsing the whole chart window
  # into a single bucket. The step never goes finer than period_seconds itself (no
  # fabricated resolution below what the alarm evaluates), and coarsens automatically
  # once the range would otherwise exceed max_points points, so a wide range doesn't
  # render hundreds of bars.
  #
  # `direction: :backward` (default) accumulates each point over the window ending at
  # it — correct for an observed metric like precipitation. `direction: :forward`
  # accumulates over the window starting at it instead, mirroring a forecast_precip
  # alarm's own look-ahead evaluation (see AlarmEvaluationEngine#collect_period_datapoints)
  # — otherwise the chart would tell a backward story for an alarm that evaluates forward.
  def self.history_series_for_range(alarm:, from:, to:, direction: :backward, step_seconds: 1.hour.to_i, max_points: 96)
    window_seconds = alarm.period_seconds
    step = [ window_seconds, step_seconds ].min
    step = [ step, ((to - from) / max_points).ceil ].max
    periods = ((to - from) / step).ceil
    collector = new(river_basin: alarm.river_basin, monitoring_stations: Array(alarm.monitoring_station),
                     river: alarm.river, forecast_source: alarm.forecast_source)

    points = (0...periods).map { |i|
      if direction == :forward
        period_start = [ from + (i * step), to ].min
        value = collector.collect(alarm.metric_name, period_start, period_start + window_seconds, alarm.statistic)
        { period_end: period_start, value: value }
      else
        period_end = [ to - (i * step), from ].max
        value = collector.collect(alarm.metric_name, period_end - window_seconds, period_end, alarm.statistic)
        { period_end: period_end, value: value }
      end
    }

    direction == :forward ? points : points.reverse
  end

  def initialize(river_basin:, monitoring_stations: nil, river: nil, forecast_source: nil)
    @river_basin = river_basin
    @monitoring_stations = monitoring_stations
    @river = river
    @forecast_source = forecast_source
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
    sensors = effective_sensors
    return nil if sensors.none?

    readings = SensorReading.where(sensor_id: sensors)
                            .by_type("precipitation")
                            .where(recorded_at: period_start..period_end)

    apply_statistic(readings, statistic || "Sum")
  end

  # Explicit stations (alarm-level scoping) win when present; otherwise every
  # sensor configured for the basin (see RiverBasin#configured_sensors).
  def effective_sensors
    scope = @monitoring_stations.presence ? Sensor.where(monitoring_station: @monitoring_stations) : @river_basin.configured_sensors
    scope.sensor_type_pluviometer.status_active
  end

  def collect_forecast_precip(period_start, period_end)
    forecasts = WeatherForecast.where(valid_from: period_start..period_end)
    forecasts = forecasts.by_source(@forecast_source) if @forecast_source
    return nil if forecasts.none?

    forecasts.maximum(:precipitation_mm)
  end

  # nil means "no data" (not "confirmed zero") for every statistic except
  # SampleCount, where a count of 0 readings is itself a real, meaningful
  # answer — AlarmEvaluationEngine relies on this nil to treat the period as
  # missing instead of silently evaluating "0mm, all clear".
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
