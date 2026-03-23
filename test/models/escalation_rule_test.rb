require "test_helper"

class EscalationRuleTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    rule = EscalationRule.new(
      from_severity: 1,
      to_severity: 2,
      escalation_after_minutes: 60
    )
    assert rule.valid?
  end

  test "invalid without from_severity" do
    rule = escalation_rules(:attention_to_alert)
    rule.from_severity = nil
    assert_not rule.valid?
  end

  test "invalid without to_severity" do
    rule = escalation_rules(:attention_to_alert)
    rule.to_severity = nil
    assert_not rule.valid?
  end

  test "invalid without escalation_after_minutes" do
    rule = escalation_rules(:attention_to_alert)
    rule.escalation_after_minutes = nil
    assert_not rule.valid?
  end

  test "from_severity must be between 1 and 4" do
    rule = escalation_rules(:attention_to_alert)

    rule.from_severity = 0
    assert_not rule.valid?

    rule.from_severity = 5
    assert_not rule.valid?
  end

  test "to_severity must be between 1 and 4" do
    rule = escalation_rules(:attention_to_alert)

    rule.to_severity = 0
    assert_not rule.valid?

    rule.to_severity = 5
    assert_not rule.valid?
  end

  test "escalation_after_minutes must be greater than 0" do
    rule = escalation_rules(:attention_to_alert)
    rule.escalation_after_minutes = 0
    assert_not rule.valid?

    rule.escalation_after_minutes = -1
    assert_not rule.valid?
  end

  # ── Scopes ──

  test "active scope returns only active rules" do
    active = EscalationRule.active
    assert_includes active, escalation_rules(:attention_to_alert)
    assert_includes active, escalation_rules(:alert_to_high)
  end
end
