class AnomalyBaselineComputer
  def self.compute(metric_name:, river_basin:, river: nil, training_window_days: 90)
    new(metric_name: metric_name, river_basin: river_basin, river: river, training_window_days: training_window_days).compute
  end

  def initialize(metric_name:, river_basin:, river: nil, training_window_days: 90)
    @metric_name = metric_name
    @river_basin = river_basin
    @river = river
    @training_window_days = training_window_days
  end

  def compute
    readings = collect_historical_data
    baseline_data = build_baseline(readings)

    baseline = AnomalyBaseline.find_or_initialize_by(
      metric_name: @metric_name,
      river_basin: @river_basin,
      river: @river
    )

    baseline.update!(
      baseline_data: baseline_data,
      computed_at: Time.current,
      training_window_days: @training_window_days
    )

    baseline
  end

  private

  def collect_historical_data
    since = @training_window_days.days.ago

    case @metric_name
    when "precipitation_1h", "precipitation_3h"
      collect_precipitation_data(since)
    when "river_level"
      collect_river_level_data(since)
    when "risk_score"
      collect_risk_score_data(since)
    else
      []
    end
  end

  def collect_precipitation_data(since)
    sensor_ids = pluviometer_ids
    return [] if sensor_ids.empty?

    SensorReading.where(sensor_id: sensor_ids)
                 .by_type("precipitation")
                 .since(since)
                 .select(:value, :recorded_at)
                 .map { |r| { value: r.value, time: r.recorded_at } }
  end

  def collect_river_level_data(since)
    return [] unless @river

    gauge_ids = Sensor.joins(:monitoring_station)
                      .where(monitoring_stations: { river_id: @river.id })
                      .where(sensor_type: :river_gauge, status: :active)
                      .pluck(:id)
    return [] if gauge_ids.empty?

    SensorReading.where(sensor_id: gauge_ids)
                 .by_type("river_level")
                 .since(since)
                 .select(:value, :recorded_at)
                 .map { |r| { value: r.value, time: r.recorded_at } }
  end

  def collect_risk_score_data(since)
    RiskAssessment.where(river_basin: @river_basin)
                  .where("assessed_at >= ?", since)
                  .select(:risk_score, :assessed_at)
                  .map { |r| { value: r.risk_score, time: r.assessed_at } }
  end

  def build_baseline(readings)
    # Initialize structure: hourly[hour][wday] = { values: [] }
    buckets = {}
    (0..23).each do |hour|
      buckets[hour.to_s] = {}
      (0..6).each do |wday|
        buckets[hour.to_s][wday.to_s] = { values: [] }
      end
    end

    # Distribute readings into buckets
    readings.each do |reading|
      time = reading[:time]
      next unless time

      hour = time.hour.to_s
      wday = time.wday.to_s
      buckets[hour][wday][:values] << reading[:value].to_f
    end

    # Compute statistics
    hourly = {}
    buckets.each do |hour, days|
      hourly[hour] = {}
      days.each do |wday, data|
        values = data[:values]
        if values.empty?
          hourly[hour][wday] = { "mean" => 0.0, "stddev" => 0.0, "count" => 0 }
        else
          mean = values.sum / values.size.to_f
          variance = values.sum { |v| (v - mean)**2 } / values.size.to_f
          stddev = Math.sqrt(variance)
          hourly[hour][wday] = { "mean" => mean.round(4), "stddev" => stddev.round(4), "count" => values.size }
        end
      end
    end

    { "hourly" => hourly }
  end

  def pluviometer_ids
    if @river_basin.geometry
      ids = Sensor.joins(:monitoring_station)
                  .where(sensor_type: :pluviometer, status: :active)
                  .where("ST_DWithin(monitoring_stations.location::geography, ?::geography, 5000)", @river_basin.geometry)
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
