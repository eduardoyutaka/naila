class AlertThreshold < ApplicationRecord
  belongs_to :risk_zone, optional: true
  belongs_to :river, optional: true
  has_many :alerts, dependent: :nullify

  validates :parameter, :threshold_type, :severity, :value, :unit, :comparison, presence: true
  validates :severity, numericality: { in: 1..4 }
  validates :comparison, inclusion: { in: %w[gt gte lt lte] }

  scope :active, -> { where(active: true) }
  scope :global, -> { where(risk_zone_id: nil, river_id: nil) }
end
