class AlarmThreshold < ApplicationRecord
  belongs_to :alarm

  validates :severity, presence: true, numericality: { in: 1..4 }
  validates :comparison_operator, presence: true, inclusion: { in: Alarm::COMPARISON_OPERATORS }
  validates :threshold_value, presence: true, numericality: true
  validates :unit, length: { maximum: 20 }, allow_nil: true
  validates :severity, uniqueness: { scope: :alarm_id, message: "já existe para este alarme" }

  def breached_by?(value)
    case comparison_operator
    when "GreaterThanThreshold"          then value > threshold_value
    when "GreaterThanOrEqualToThreshold" then value >= threshold_value
    when "LessThanThreshold"             then value < threshold_value
    when "LessThanOrEqualToThreshold"    then value <= threshold_value
    else false
    end
  end
end
