require "test_helper"

class AlarmEvaluationJobTest < ActiveSupport::TestCase
  test "evaluates all alarms when scope is 'all'" do
    assert_nothing_raised do
      AlarmEvaluationJob.perform_now("all")
    end
  end

  test "evaluates single alarm by id" do
    alarm = alarms(:precip_3h_belem)

    assert_nothing_raised do
      AlarmEvaluationJob.perform_now(alarm.id)
    end

    assert_not_nil alarm.reload.last_evaluated_at
  end

  test "skips non-existent alarm ids gracefully" do
    assert_nothing_raised do
      AlarmEvaluationJob.perform_now(-1)
    end
  end
end
