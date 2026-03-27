class FetchInmetJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "INMET")
    client = InmetClient.new(data_source)

    stations = MonitoringStation.where(data_source: "INMET").where(status: "active")
    affected_basin_ids = Set.new

    stations.find_each do |station|
      observations = client.call(station_code: station.external_id)
      next if observations.empty?

      observations.each do |attrs|
        WeatherObservation.find_or_create_by!(
          source: attrs[:source],
          station_code: attrs[:station_code],
          observed_at: attrs[:observed_at]
        ) do |o|
          o.assign_attributes(attrs.except(:source, :station_code, :observed_at))
          o.location = station.location
        end
      end

      affected_basin_ids.merge(station.nearby_river_basin_ids)
    end

    affected_basin_ids.each do |basin_id|
      RiskAssessmentJob.perform_later(basin_id)
    end
  end
end
