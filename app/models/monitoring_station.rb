class MonitoringStation < ApplicationRecord
  belongs_to :neighborhood, optional: true
  belongs_to :river_basin
  belongs_to :river, optional: true
  has_many :sensors, dependent: :destroy
  has_many :sensor_readings, through: :sensors

  validates :external_id, :name, :data_source, presence: true
  validates :external_id, uniqueness: { scope: :data_source }

  enum :status, {
    active: "active",
    inactive: "inactive",
    maintenance: "maintenance"
  }, prefix: true

  enum :connection_status, {
    unknown: "unknown",
    connected: "connected",
    disconnected: "disconnected"
  }, prefix: true

  scope :online, -> { where(status: "active") }
  scope :by_status, ->(status) { where(status: status) }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{sanitize_sql_like(term)}%") if term.present? }
  scope :connected, -> { where(connection_status: "connected") }
  scope :disconnected, -> { where(connection_status: "disconnected") }

  def nearby_river_basin_ids
    return [] unless location

    RiverBasin.active
              .where("ST_DWithin(geometry::geography, ?::geography, 5000)", location)
              .pluck(:id)
  end

  def last_reading
    sensor_readings.recent.first
  end

  def record_fetch_success!
    update!(connection_status: "connected", last_successful_fetch_at: Time.current)
  end

  def record_fetch_failure!
    update!(connection_status: "disconnected", last_failed_fetch_at: Time.current)
  end
end
