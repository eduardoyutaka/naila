require "test_helper"

class NotificationRuleTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with role targeting and no specific users" do
    rule = notification_rules(:email_admins_alerta)
    assert rule.valid?
  end

  test "valid with specific user and no role targeting" do
    rule = notification_rules(:email_specific_user)
    assert rule.valid?
  end

  test "invalid without name" do
    rule = notification_rules(:email_admins_alerta)
    rule.name = nil
    assert_not rule.valid?
  end

  test "invalid with unknown channel" do
    rule = notification_rules(:email_admins_alerta)
    rule.channel = "pager"
    assert_not rule.valid?
    assert_includes rule.errors[:channel], "não está incluído na lista"
  end

  test "invalid with min_severity outside 1..4" do
    rule = notification_rules(:email_admins_alerta)
    rule.min_severity = 0
    assert_not rule.valid?

    rule.min_severity = 5
    assert_not rule.valid?
  end

  test "invalid when no role is targeted and no users assigned" do
    rule = NotificationRule.new(name: "Vazia", channel: "email", min_severity: 1)
    assert_not rule.valid?
    assert_includes rule.errors[:base], "selecione ao menos um cargo ou usuário específico"
  end

  # ── Scopes ──

  test "enabled scope returns only enabled rules" do
    assert_includes NotificationRule.enabled, notification_rules(:email_admins_alerta)
    assert_not_includes NotificationRule.enabled, notification_rules(:disabled_rule)
  end

  test "for_channel scope filters by channel" do
    email_rules = NotificationRule.for_channel("email")
    assert_includes email_rules, notification_rules(:email_admins_alerta)
    assert_not_includes email_rules, notification_rules(:sms_coordinators_emergency)
  end

  test "triggered_by_severity scope includes rules at or below the given severity" do
    rules = NotificationRule.triggered_by_severity(3)
    assert_includes rules, notification_rules(:email_admins_alerta) # min 2
    assert_includes rules, notification_rules(:sms_all_roles_high)  # min 3
    assert_not_includes rules, notification_rules(:sms_coordinators_emergency) # min 4
  end

  # ── resolved_recipients ──

  test "resolved_recipients returns users matching the targeted role" do
    rule = notification_rules(:email_admins_alerta)
    assert_includes rule.resolved_recipients, users(:admin)
    assert_not_includes rule.resolved_recipients, users(:coordinator)
  end

  test "resolved_recipients returns users targeted by multiple roles" do
    rule = notification_rules(:sms_all_roles_high)
    assert_includes rule.resolved_recipients, users(:admin)
    assert_includes rule.resolved_recipients, users(:coordinator)
  end

  test "resolved_recipients returns users targeted explicitly" do
    rule = notification_rules(:email_specific_user)
    assert_includes rule.resolved_recipients, users(:operator)
  end

  test "resolved_recipients excludes inactive users" do
    rule = notification_rules(:sms_all_roles_high)
    assert_not_includes rule.resolved_recipients, users(:inactive)
  end

  test "resolved_recipients dedupes users matched by role and explicit list" do
    rule = notification_rules(:email_admins_alerta)
    rule.users << users(:admin)
    assert_equal 1, rule.resolved_recipients.where(id: users(:admin).id).count
  end

  test "resolved_recipients filters users without phone_number when channel is sms" do
    rule = notification_rules(:sms_all_roles_high)
    # operator has no phone_number in fixtures
    assert_not_includes rule.resolved_recipients, users(:operator)
    assert_includes rule.resolved_recipients, users(:admin)
  end

  test "resolved_recipients keeps users without phone_number when channel is email" do
    rule = notification_rules(:email_admins_alerta)
    rule.users << users(:operator) # no phone
    assert_includes rule.resolved_recipients, users(:operator)
  end

  # ── Associations ──

  test "destroying a rule removes notification_rule_users" do
    rule = notification_rules(:email_specific_user)
    assert_difference "NotificationRuleUser.count", -1 do
      rule.destroy
    end
  end

  # ── Helpers ──

  test "targeted_role_labels returns pt-BR names" do
    rule = notification_rules(:sms_all_roles_high)
    assert_equal [ "Administradores", "Coordenadores", "Operadores" ], rule.targeted_role_labels
  end
end
