class WeatherIngestionCycleJob < ApplicationJob
  queue_as :weather_ingestion

  JOB_MAP = {
    "Open-Meteo" => FetchOpenMeteoJob,
    "OpenWeatherMap" => FetchOpenWeatherMapJob,
    "CEMADEN" => FetchCemadenJob
  }.freeze

  def perform
    DataSource.where(source_type: "api").find_each do |source|
      next if source.status == "offline" && !source.can_retry?
      next unless source.due_for_fetch?

      job_class = JOB_MAP[source.name]
      next unless job_class

      job_class.perform_later
      Rails.logger.info("[WeatherIngestionCycleJob] Enqueued #{job_class.name} for #{source.name}")
    end
  end
end
