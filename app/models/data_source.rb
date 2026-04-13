class DataSource < ApplicationRecord
  validates :name, :source_type, presence: true
  validates :source_type, inclusion: { in: %w[api mqtt webhook] }

  scope :active, -> { where(status: "active") }
  scope :degraded, -> { where(status: "degraded") }
  scope :offline, -> { where(status: "offline") }

  RETRY_COOLDOWN = 5.minutes

  CLIENT_MAP = {
    "Open-Meteo" => "OpenMeteoClient",
    "OpenWeatherMap" => "OpenWeatherMapClient",
    "INMET" => "InmetClient",
    "CEMADEN" => "CemadenClient"
  }.freeze

  def due_for_fetch?
    last_successful_fetch_at.nil? || last_successful_fetch_at < fetch_interval_seconds.seconds.ago
  end

  def can_retry?
    status == "offline" && last_failed_fetch_at.present? && last_failed_fetch_at < RETRY_COOLDOWN.ago
  end

  def client_class
    class_name = CLIENT_MAP[name]
    class_name&.constantize
  end

  def record_success!
    update!(
      status: "active",
      last_successful_fetch_at: Time.current,
      consecutive_failures: 0
    )
  end

  def record_failure!
    new_failures = consecutive_failures + 1
    new_status = new_failures >= 3 ? "offline" : "degraded"

    update!(
      status: new_status,
      last_failed_fetch_at: Time.current,
      consecutive_failures: new_failures
    )
  end
end
