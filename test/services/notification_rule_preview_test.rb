require "test_helper"

class NotificationRulePreviewTest < ActiveSupport::TestCase
  test "returns empty preview when alarm has no current_severity" do
    alarm = alarms(:precip_3h_belem) # state: ok, no current_severity
    preview = NotificationRulePreview.for_alarm(alarm)

    assert_not preview.fires_any?
    assert_equal 0, preview.rule_count
    assert_equal 0, preview.email_recipient_count
    assert_equal 0, preview.sms_recipient_count
  end

  test "returns rule and recipient counts at a given severity" do
    alarm = alarms(:flood_alert_belem) # current_severity 3
    preview = NotificationRulePreview.for_alarm(alarm)

    # At sev 3: email_admins_alerta (sev 2+), sms_all_roles_high (sev 3+),
    # email_specific_user (sev 2+). disabled_rule is disabled. sms_coordinators_emergency
    # requires sev 4+, so skipped.
    assert preview.fires_any?
    assert_equal 3, preview.rule_count
    assert_operator preview.email_recipient_count, :>=, 1
    assert_operator preview.sms_recipient_count, :>=, 1
  end

  test "dedupes recipients matched by multiple rules per channel" do
    alarm = alarms(:flood_alert_belem)
    alarm.update!(current_severity: 4)
    preview = NotificationRulePreview.for_alarm(alarm)

    # At sev 4, multiple email rules match admin; dedup should count admin once for email.
    # We compute the union ourselves as a cross-check.
    email_ids = NotificationRule.enabled
      .for_channel("email")
      .triggered_by_severity(4)
      .flat_map { |r| r.resolved_recipients.pluck(:id) }
      .uniq
    assert_equal email_ids.size, preview.email_recipient_count
  end

  test "skips disabled rules" do
    alarm = alarms(:flood_alert_belem)
    alarm.update!(current_severity: 1)
    preview = NotificationRulePreview.for_alarm(alarm)

    # Only disabled_rule targets sev 1, and it's disabled — nothing fires.
    assert_not preview.fires_any?
    assert_equal 0, preview.rule_count
  end
end
