class SensorStation < ApplicationRecord
  belongs_to :neighborhood, optional: true
  belongs_to :drainage_basin, optional: true
  belongs_to :river, optional: true
  has_many :sensor_readings, dependent: :destroy

  validates :external_id, :name, :station_type, :data_source, presence: true
  validates :external_id, uniqueness: { scope: :data_source }

  enum :station_type, {
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

  def nearby_risk_zone_ids
    return [] unless location

    RiskZone.active
            .where("ST_DWithin(geometry::geography, ?::geography, 5000)", location)
            .pluck(:id)
  end
end
