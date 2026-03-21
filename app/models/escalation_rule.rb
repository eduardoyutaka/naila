class EscalationRule < ApplicationRecord
  validates :from_severity, :to_severity, :escalation_after_minutes, presence: true
  validates :from_severity, :to_severity, numericality: { in: 1..4 }
  validates :escalation_after_minutes, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
end
