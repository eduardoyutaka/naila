class RiskZone < ApplicationRecord
  belongs_to :drainage_basin, optional: true
  belongs_to :neighborhood, optional: true
  has_many :risk_assessments, dependent: :destroy
  has_many :alerts, dependent: :nullify
  has_many :alert_thresholds, dependent: :destroy
  has_many :evacuation_routes, dependent: :destroy

  validates :name, :zone_type, presence: true

  enum :zone_type, {
    flood_plain: "flood_plain",
    slope: "slope",
    urban_drainage: "urban_drainage"
  }, prefix: true

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
