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

  RISK_LEVEL_SEVERITIES = {
    "normal"     => 0,
    "attention"  => 1,
    "alert"      => 2,
    "high_alert" => 3,
    "emergency"  => 4
  }.freeze

  scope :active, -> { where(active: true) }
  scope :by_active, ->(val) { where(active: val) }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{sanitize_sql_like(term)}%") if term.present? }

  scope :at_risk, -> {
    where(id: Alarm.in_alarm.where.not(river_basin_id: nil).distinct.select(:river_basin_id))
  }

  scope :by_risk_level, ->(level) {
    severity = RISK_LEVEL_SEVERITIES[level.to_s]
    next all if severity.nil?

    in_alarm_basins = Alarm.in_alarm.where.not(river_basin_id: nil).distinct.select(:river_basin_id)
    if severity.zero?
      where.not(id: in_alarm_basins)
    else
      where(id: Alarm.in_alarm.where.not(river_basin_id: nil)
        .group(:river_basin_id)
        .having("MAX(current_severity) = ?", severity)
        .select(:river_basin_id))
    end
  }

  scope :ordered_by_alarm_severity, -> {
    left_joins(:alarms).group("river_basins.id").order(
      Arel.sql("MAX(CASE WHEN alarms.state = 'alarm' THEN alarms.current_severity END) DESC NULLS LAST"),
      :name
    )
  }

  def alarm_severity
    Alarm.in_alarm.where(river_basin_id: id).maximum(:current_severity) || 0
  end

  def monitored?
    alarms.exists?
  end

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
