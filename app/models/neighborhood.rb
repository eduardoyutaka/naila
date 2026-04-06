class Neighborhood < ApplicationRecord
  belongs_to :region
  has_many :monitoring_stations, dependent: :nullify

  validates :name, :code, presence: true
  validates :code, uniqueness: true

  enum :current_risk_level, {
    normal: 0,
    attention: 1,
    alert: 2,
    high_alert: 3,
    emergency: 4
  }, prefix: :risk
end
