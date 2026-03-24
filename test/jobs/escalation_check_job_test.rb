require "test_helper"

class EscalationCheckJobTest < ActiveSupport::TestCase
  test "calls EscalationEvaluator.check_escalations" do
    alert = alerts(:active_attention)
    alert.update!(created_at: 35.minutes.ago, activated_at: 35.minutes.ago)

    EscalationCheckJob.perform_now

    alert.reload
    assert_equal 2, alert.severity
  end
end
