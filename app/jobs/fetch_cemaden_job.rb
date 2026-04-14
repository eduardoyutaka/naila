class FetchCemadenJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "CEMADEN")
    client = CemadenClient.new(data_source)

    stations = MonitoringStation.where(data_source: "CEMADEN").where(status: "active")
    affected_basin_ids = Set.new

    stations.find_each do |station|
      sensor = station.sensors.where(sensor_type: :pluviometer, status: :active).first
      next unless sensor

      readings = client.call(station_code: station.external_id)
      next if readings.empty?

      readings.each do |attrs|
        SensorReading.find_or_create_by!(
          sensor: sensor,
          reading_type: attrs[:reading_type],
          recorded_at: attrs[:recorded_at]
        ) do |r|
          r.value = attrs[:value]
          r.unit = attrs[:unit]
          r.raw_payload = attrs[:raw_data]
        end
      end

      affected_basin_ids.merge(station.nearby_river_basin_ids)
    end

    affected_basin_ids.each do |basin_id|
      RiskAssessmentJob.perform_later(basin_id)
    end
  end
end
