class Sensor < ApplicationRecord
  belongs_to :monitoring_station
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

  # Returns active pluviometers within radius_m metres of river_basin's centroid.
  # Falls back to pluviometers assigned to the basin's monitoring stations when
  # no geometry is set or no spatial results are found.
  def self.nearby_pluviometers(river_basin, radius_m: 5000)
    if river_basin.geometry
      ids = joins(:monitoring_station)
              .where(sensor_type: :pluviometer, status: :active)
              .where("ST_DWithin(monitoring_stations.location::geography, ?::geography, ?)", river_basin.geometry, radius_m)
              .pluck(:id)
      return where(id: ids) if ids.any?
    end
    joins(:monitoring_station)
      .where(sensor_type: :pluviometer, status: :active)
      .where(monitoring_stations: { river_basin_id: river_basin.id })
  rescue ActiveRecord::StatementInvalid
    none
  end
end
