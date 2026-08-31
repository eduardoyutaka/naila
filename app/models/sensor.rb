class Sensor < ApplicationRecord
  belongs_to :monitoring_station
  has_many :sensor_readings, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :sensor_type, presence: true

  enum :sensor_type, {
    pluviometer: "pluviometer",
    weather_station: "weather_station"
  }, prefix: true

  enum :status, {
    active: "active",
    inactive: "inactive",
    maintenance: "maintenance"
  }, prefix: true

  scope :online, -> { where(status: "active") }
  scope :by_type, ->(type) { where(sensor_type: type) }

  def last_reading
    sensor_readings.recent.first
  end
end
