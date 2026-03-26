class Sensor < ApplicationRecord
  belongs_to :sensor_station
  has_many :sensor_readings, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :sensor_type, presence: true

  enum :sensor_type, {
    pluviometer: "pluviometer",
    river_gauge: "river_gauge",
    weather_station: "weather_station"
  }, prefix: true

  enum :status, {
    active: "active",
    inactive: "inactive",
    maintenance: "maintenance"
  }, prefix: true

  scope :online, -> { where(status: "active") }
  scope :by_type, ->(type) { where(sensor_type: type) }
end
