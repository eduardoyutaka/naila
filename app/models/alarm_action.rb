class AlarmAction < ApplicationRecord
  TRIGGER_STATES = %w[alarm ok insufficient_data].freeze
  ACTION_TYPES = %w[notification webhook].freeze

  # `configuration` is a JSONB bag used only by webhook actions (url / method /
  # headers). The legacy `"channels"` key on notification actions is unread —
  # email/SMS dispatch is now governed globally by NotificationRule records.
  belongs_to :alarm

  validates :trigger_state, presence: true, inclusion: { in: TRIGGER_STATES }
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }

  scope :enabled, -> { where(enabled: true) }
  scope :for_state, ->(state) { where(trigger_state: state) }
end
