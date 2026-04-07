class FetchCemadenJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "CEMADEN")
    client = CemadenClient.new(data_source)
    readings = client.call

    return if readings.empty?

    # Batch-load all CEMADEN stations and their pluviometer sensors to avoid O(n) DB queries
    station_map = MonitoringStation.where(data_source: "CEMADEN")
                                   .index_by(&:external_id)
    station_ids = station_map.values.map(&:id)
    sensor_map = Sensor.where(monitoring_station_id: station_ids, sensor_type: :pluviometer, status: :active)
                       .index_by(&:monitoring_station_id)

    affected_basin_ids = Set.new

    readings.each do |attrs|
      station = station_map[attrs[:station_code]]
      next unless station

      sensor = sensor_map[station.id]
      next unless sensor

      SensorReading.find_or_create_by!(
        sensor: sensor,
        reading_type: attrs[:reading_type],
        recorded_at: attrs[:recorded_at]
      ) do |r|
        r.value = attrs[:value]
        r.unit = attrs[:unit]
        r.raw_payload = attrs[:raw_data]
      end

      affected_basin_ids.merge(station.nearby_river_basin_ids)
    end

    affected_basin_ids.each do |basin_id|
      RiskAssessmentJob.perform_later(basin_id)
    end
  end
end
