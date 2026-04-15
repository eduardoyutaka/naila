class NotificationRuleUser < ApplicationRecord
  belongs_to :notification_rule
  belongs_to :user

  validates :user_id, uniqueness: { scope: :notification_rule_id }
end
