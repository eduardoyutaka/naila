class FetchCemadenJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "CEMADEN")
    client = CemadenClient.new(data_source)
    readings = client.call

    return if readings.empty?

    affected_basin_ids = Set.new

    readings.each do |attrs|
      station = SensorStation.find_by(external_id: attrs[:station_code], data_source: "CEMADEN")
      next unless station

      SensorReading.find_or_create_by!(
        sensor_station: station,
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
