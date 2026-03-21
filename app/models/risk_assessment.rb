class RiskAssessment < ApplicationRecord
  belongs_to :risk_zone

  validates :assessed_at, :risk_level, :risk_score, presence: true
  validates :risk_score, numericality: { in: 0.0..1.0 }
  validates :risk_level, numericality: { in: 0..4 }

  scope :recent, -> { order(assessed_at: :desc) }
end
