class AlarmStateHistory < ApplicationRecord
  STATES = Alarm::STATES

  belongs_to :alarm

  validates :previous_state, presence: true, inclusion: { in: STATES }
  validates :new_state, presence: true, inclusion: { in: STATES }
  validates :reason, presence: true
  validates :evaluated_at, presence: true
end
