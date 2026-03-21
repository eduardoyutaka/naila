class DrainageBasin < ApplicationRecord
  has_many :rivers, dependent: :destroy
  has_many :risk_zones, dependent: :nullify
  has_many :sensor_stations, dependent: :nullify

  validates :name, presence: true
end
