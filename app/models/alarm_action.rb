class AlarmAction < ApplicationRecord
  TRIGGER_STATES = %w[alarm ok insufficient_data].freeze
  ACTION_TYPES = %w[notification].freeze

  belongs_to :alarm

  validates :trigger_state, presence: true, inclusion: { in: TRIGGER_STATES }
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  # current_severity is only ever a real 1-4 value when trigger_state is "alarm" (it's
  # always 0 for "ok", always nil for "insufficient_data" — see Alarm#transition_to!),
  # so min_severity on any other trigger would be a permanently unreachable gate.
  validates :min_severity, absence: { message: "só se aplica quando o gatilho é Alarme" }, unless: -> { trigger_state == "alarm" }

  scope :for_state, ->(state) { where(trigger_state: state) }
end
