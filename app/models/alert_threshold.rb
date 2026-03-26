class AlertThreshold < ApplicationRecord
  belongs_to :river_basin, optional: true
  belongs_to :river, optional: true
  has_many :alerts, dependent: :nullify

  validates :parameter, :threshold_type, :severity, :value, :unit, :comparison, presence: true
  validates :severity, numericality: { in: 1..4 }
  validates :comparison, inclusion: { in: %w[gt gte lt lte] }

  scope :active, -> { where(active: true) }
  scope :global, -> { where(river_basin_id: nil, river_id: nil) }
end
