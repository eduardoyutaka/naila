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

  scope :online, -> { where(status: "active") }

  def nearby_river_basin_ids
    return [] unless location

    RiverBasin.active
              .where("ST_DWithin(geometry::geography, ?::geography, 5000)", location)
              .pluck(:id)
  end
end
