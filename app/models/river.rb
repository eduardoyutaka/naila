class River < ApplicationRecord
  belongs_to :river_basin
  has_many :sensor_stations, dependent: :nullify
  has_many :alerts, dependent: :nullify
  has_many :alert_thresholds, dependent: :destroy

  validates :name, presence: true
  validates :normal_level_m, :alert_level_m, :flood_level_m, :overflow_level_m,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
