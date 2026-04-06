class AlarmThreshold < ApplicationRecord
  belongs_to :alarm

  validates :severity, presence: true, numericality: { in: 1..4 }
  validates :comparison_operator, presence: true, inclusion: { in: Alarm::COMPARISON_OPERATORS }
  validates :threshold_value, presence: true, numericality: true
  validates :unit, length: { maximum: 20 }, allow_nil: true
  validates :severity, uniqueness: { scope: :alarm_id, message: "já existe para este alarme" }
end
