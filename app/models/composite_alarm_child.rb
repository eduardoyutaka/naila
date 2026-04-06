class CompositeAlarmChild < ApplicationRecord
  belongs_to :composite_alarm, class_name: "Alarm"
  belongs_to :child_alarm, class_name: "Alarm"

  validates :composite_alarm_id, uniqueness: { scope: :child_alarm_id }
  validate :composite_alarm_must_be_composite
  validate :child_alarm_cannot_be_composite

  private

  def composite_alarm_must_be_composite
    return unless composite_alarm

    unless composite_alarm.composite?
      errors.add(:composite_alarm, "must be a composite alarm")
    end
  end

  def child_alarm_cannot_be_composite
    return unless child_alarm

    if child_alarm.composite?
      errors.add(:child_alarm, "cannot be a composite alarm")
    end
  end
end
