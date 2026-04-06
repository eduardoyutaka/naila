require "test_helper"

class AlarmStateHistoryTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    history = AlarmStateHistory.new(
      alarm: alarms(:precip_3h_belem),
      previous_state: "ok",
      new_state: "alarm",
      reason: "2 of 3 breached threshold",
      evaluated_at: Time.current
    )
    assert history.valid?
  end

  test "invalid without alarm" do
    history = alarm_state_histories(:river_to_alarm)
    history.alarm = nil
    assert_not history.valid?
  end

  test "invalid without previous_state" do
    history = alarm_state_histories(:river_to_alarm)
    history.previous_state = nil
    assert_not history.valid?
  end

  test "invalid without new_state" do
    history = alarm_state_histories(:river_to_alarm)
    history.new_state = nil
    assert_not history.valid?
  end

  test "invalid without reason" do
    history = alarm_state_histories(:river_to_alarm)
    history.reason = nil
    assert_not history.valid?
  end

  test "invalid without evaluated_at" do
    history = alarm_state_histories(:river_to_alarm)
    history.evaluated_at = nil
    assert_not history.valid?
  end

  test "invalid with unknown previous_state" do
    history = alarm_state_histories(:river_to_alarm)
    history.previous_state = "critical"
    assert_not history.valid?
  end

  test "invalid with unknown new_state" do
    history = alarm_state_histories(:river_to_alarm)
    history.new_state = "critical"
    assert_not history.valid?
  end

  # ── Associations ──

  test "belongs to alarm" do
    assert_equal alarms(:river_level_belem), alarm_state_histories(:river_to_alarm).alarm
  end

  # ── Defaults ──

  test "datapoints defaults to empty array" do
    history = AlarmStateHistory.new
    assert_equal [], history.datapoints
  end
end
