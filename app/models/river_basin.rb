class RiverBasin < ApplicationRecord
  has_many :rivers, dependent: :destroy
  has_many :sensor_stations, dependent: :nullify
  has_many :risk_assessments, dependent: :destroy
  has_many :alerts, dependent: :nullify
  has_many :alert_thresholds, dependent: :destroy
  has_many :evacuation_routes, dependent: :destroy

  validates :name, presence: true

  enum :current_risk_level, {
    normal: 0,
    attention: 1,
    alert: 2,
    high_alert: 3,
    emergency: 4
  }, prefix: :risk

  scope :active, -> { where(active: true) }
  scope :at_risk, -> { where("current_risk_level > 0") }
end
