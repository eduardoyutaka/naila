require "test_helper"

class AlarmEvaluationEngineCompositeTest < ActiveSupport::TestCase
  setup do
    @composite = alarms(:composite_flood_belem)
    @precip_alarm = alarms(:precip_3h_belem)
    @river_alarm = alarms(:river_level_belem)
  end

  test "composite alarm transitions to alarm when rule evaluates to true" do
    # Rule: ALARM(precip_3h_belem) AND ALARM(river_level_belem)
    # precip is ok, river is alarm → AND = false → composite stays ok
    assert_equal "ok", @precip_alarm.state
    assert_equal "alarm", @river_alarm.state

    AlarmEvaluationEngine.evaluate_alarm(@composite)
    assert_equal "ok", @composite.reload.state

    # Now set precip to alarm
    @precip_alarm.update!(state: "alarm")

    AlarmEvaluationEngine.evaluate_alarm(@composite)
    assert_equal "alarm", @composite.reload.state
  end

  test "composite alarm transitions to ok when rule no longer true" do
    # Set composite to alarm state first
    @precip_alarm.update!(state: "alarm")
    @composite.update!(state: "alarm", state_changed_at: 1.hour.ago)

    # Now recover precip
    @precip_alarm.update!(state: "ok")

    AlarmEvaluationEngine.evaluate_alarm(@composite)
    assert_equal "ok", @composite.reload.state
  end

  test "composite alarm transitions to insufficient_data when child is insufficient" do
    @precip_alarm.update!(state: "insufficient_data")
    @river_alarm.update!(state: "ok")

    AlarmEvaluationEngine.evaluate_alarm(@composite)
    assert_equal "insufficient_data", @composite.reload.state
  end

  test "composite alarm creates state history on transition" do
    @precip_alarm.update!(state: "alarm")
    # composite is currently ok, both children in alarm → should transition

    assert_difference "AlarmStateHistory.count", 1 do
      AlarmEvaluationEngine.evaluate_alarm(@composite)
    end

    history = @composite.alarm_state_histories.order(:created_at).last
    assert_equal "ok", history.previous_state
    assert_equal "alarm", history.new_state
  end

  test "composite alarm is no-op when state unchanged" do
    # precip=ok, river=alarm → AND = false → composite stays ok
    assert_no_difference "AlarmStateHistory.count" do
      AlarmEvaluationEngine.evaluate_alarm(@composite)
    end
  end

  test "evaluate_all includes composite alarms" do
    # Lower thresholds so fixture data actually triggers both alarms
    @precip_alarm.update!(state: "ok", threshold_value: 5.0, evaluation_periods: 1, datapoints_to_alarm: 1)
    @river_alarm.update!(state: "ok", threshold_value: 0.5, period_seconds: 3600, evaluation_periods: 1, datapoints_to_alarm: 1)

    AlarmEvaluationEngine.evaluate_all

    # Both metric alarms should now be in alarm (data breaches low thresholds)
    assert_equal "alarm", @precip_alarm.reload.state
    assert_equal "alarm", @river_alarm.reload.state
    assert_equal "alarm", @composite.reload.state
  end
end
