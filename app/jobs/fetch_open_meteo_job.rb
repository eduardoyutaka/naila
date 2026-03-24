class FetchOpenMeteoJob < ApplicationJob
  queue_as :weather_ingestion

  def perform
    data_source = DataSource.find_by!(name: "Open-Meteo")
    client = OpenMeteoClient.new(data_source)
    forecasts = client.call

    return if forecasts.empty?

    forecasts.each do |attrs|
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
