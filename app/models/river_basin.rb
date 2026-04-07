class RiverBasin < ApplicationRecord
  has_many :rivers, dependent: :destroy
  has_many :monitoring_stations, dependent: :destroy
  has_one :monitoring_station  # convenience for the intended 1:1 relationship
  has_many :sensors, through: :monitoring_stations
  has_many :sensor_readings, through: :sensors
  has_many :risk_assessments, dependent: :destroy
  has_many :alarms, dependent: :nullify
  has_many :evacuation_routes, dependent: :destroy

  attr_writer :geometry_geojson

  validates :name, presence: true

  before_validation :parse_geometry_geojson

  enum :current_risk_level, {
    normal: 0,
    attention: 1,
    alert: 2,
    high_alert: 3,
    emergency: 4
  }, prefix: :risk

  scope :active, -> { where(active: true) }
  scope :at_risk, -> { where.not(current_risk_level: :normal) }

  private

  def parse_geometry_geojson
    return unless @geometry_geojson.present?

    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    parsed = JSON.parse(@geometry_geojson)
    self.geometry = RGeo::GeoJSON.decode(parsed, geo_factory: factory)
  rescue JSON::ParserError, RGeo::Error::InvalidGeometry
    errors.add(:geometry, "inválida")
  end
end
