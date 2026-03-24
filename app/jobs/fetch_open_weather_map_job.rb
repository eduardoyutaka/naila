class FetchOpenWeatherMapJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "OpenWeatherMap")
    client = OpenWeatherMapClient.new(data_source)
    result = client.call

    return if result[:observations].empty? && result[:forecasts].empty?

    result[:observations].each do |attrs|
      WeatherObservation.find_or_create_by!(
        source: attrs[:source],
        station_code: nil,
        observed_at: attrs[:observed_at]
      ) do |o|
        o.assign_attributes(attrs.except(:source, :observed_at))
      end
    end

    result[:forecasts].each do |attrs|
      WeatherForecast.find_or_create_by!(
        source: attrs[:source],
        valid_from: attrs[:valid_from],
        valid_until: attrs[:valid_until]
      ) do |f|
        f.assign_attributes(attrs.except(:source, :valid_from, :valid_until))
      end
    end

    RiskAssessmentJob.perform_later("all")
  end
end
