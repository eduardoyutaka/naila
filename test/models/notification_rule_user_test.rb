require "test_helper"

class NotificationRuleUserTest < ActiveSupport::TestCase
  test "valid with rule and user" do
    rule = notification_rules(:email_admins_alerta)
    join = NotificationRuleUser.new(notification_rule: rule, user: users(:coordinator))
    assert join.valid?
  end

  test "invalid without notification_rule" do
    join = NotificationRuleUser.new(user: users(:coordinator))
    assert_not join.valid?
  end

  test "invalid without user" do
    join = NotificationRuleUser.new(notification_rule: notification_rules(:email_admins_alerta))
    assert_not join.valid?
  end

  test "invalid when duplicating (rule, user) pair" do
    duplicate = NotificationRuleUser.new(
      notification_rule: notification_rules(:email_specific_user),
      user: users(:operator)
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "já foi utilizado"
  end
end
