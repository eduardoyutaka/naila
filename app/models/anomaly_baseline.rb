class AnomalyBaseline < ApplicationRecord
  belongs_to :river_basin, optional: true
  belongs_to :river, optional: true

  has_many :alarms, dependent: :nullify

  validates :metric_name, presence: true
  validates :computed_at, presence: true
  validates :training_window_days, presence: true, numericality: { greater_than: 0 }
  validates :metric_name, uniqueness: { scope: %i[river_basin_id river_id] }
end
