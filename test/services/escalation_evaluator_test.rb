require "test_helper"

class EscalationEvaluatorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "escalates alert when time exceeds escalation_after_minutes" do
    alert = alerts(:active_attention) # severity 1
    # Make it old enough to escalate (rule: 1→2 after 30 min)
    alert.update!(created_at: 35.minutes.ago, activated_at: 35.minutes.ago)

    EscalationEvaluator.check_escalations

    alert.reload
    assert_equal 2, alert.severity
  end

  test "does not escalate recently created alerts" do
    alert = alerts(:active_attention) # severity 1
    alert.update!(created_at: 5.minutes.ago, activated_at: 5.minutes.ago)

    EscalationEvaluator.check_escalations

    alert.reload
    assert_equal 1, alert.severity
  end

  test "does not escalate acknowledged alerts" do
    alert = alerts(:acknowledged_alert) # severity 2, acknowledged
    alert.update!(created_at: 2.hours.ago, activated_at: 2.hours.ago)

    original_severity = alert.severity
    EscalationEvaluator.check_escalations

    alert.reload
    assert_equal original_severity, alert.severity
  end

  test "does not escalate resolved alerts" do
    alert = alerts(:resolved_alert) # severity 2, resolved
    alert.update!(created_at: 2.hours.ago, activated_at: 2.hours.ago)

    original_severity = alert.severity
    EscalationEvaluator.check_escalations

    alert.reload
    assert_equal original_severity, alert.severity
  end

  test "creates notifications on escalation" do
    alert = alerts(:active_attention) # severity 1
    alert.update!(created_at: 35.minutes.ago, activated_at: 35.minutes.ago)

    assert_difference "AlertNotification.count" do
      EscalationEvaluator.check_escalations
    end
  end
end
