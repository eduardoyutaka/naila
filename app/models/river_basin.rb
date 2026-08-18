class RiverBasin < ApplicationRecord
  has_many :rivers, dependent: :destroy
  has_many :monitoring_stations, dependent: :destroy
  has_one :monitoring_station  # convenience for the intended 1:1 relationship
  has_many :sensors, through: :monitoring_stations
  has_many :sensor_readings, through: :sensors
  has_many :alarms, dependent: :nullify
  has_many :evacuation_routes, dependent: :destroy
  has_many :flood_zones, dependent: :destroy

  attr_writer :geometry_geojson

  validates :name, presence: true

  before_validation :parse_geometry_geojson

  RISK_LEVEL_SEVERITIES = {
    "normal"     => 0,
    "attention"  => 1,
    "alert"      => 2,
    "high_alert" => 3,
    "emergency"  => 4
  }.freeze

  scope :active, -> { where(active: true) }
  scope :by_active, ->(val) { where(active: val) }
  scope :search_by_name, ->(term) { where("river_basins.name ILIKE ?", "%#{sanitize_sql_like(term)}%") if term.present? }

  scope :at_risk, -> {
    where(id: Alarm.in_alarm.where.not(river_basin_id: nil).distinct.select(:river_basin_id))
  }

  scope :by_risk_level, ->(level) {
    severity = RISK_LEVEL_SEVERITIES[level.to_s]
    next all if severity.nil?

    # Vigilância (0) and firing (1..4) are both read from Alarm#current_severity directly now
    # that "ok" alarms store an explicit 0 — no more hand-rolled set-difference for severity 0.
    # Basins monitored only by an "insufficient_data" alarm have no evaluated row and so match
    # neither branch — genuinely unknown risk isn't the same as confirmed-calm Vigilância.
    where(id: Alarm.evaluated.where.not(river_basin_id: nil)
      .group(:river_basin_id)
      .having("MAX(current_severity) = ?", severity)
      .select(:river_basin_id))
  }

  scope :ordered_by_alarm_severity, -> {
    left_joins(:alarms).group("river_basins.id").order(
      Arel.sql("MAX(CASE WHEN alarms.state IN ('ok', 'alarm') THEN alarms.current_severity END) DESC NULLS LAST"),
      :name
    )
  }

  def alarm_severity
    Alarm.evaluated.where(river_basin_id: id).maximum(:current_severity) || 0
  end

  def monitored?
    alarms.any?
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
