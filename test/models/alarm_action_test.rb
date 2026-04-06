require "test_helper"

class AlarmActionTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    action = AlarmAction.new(
      alarm: alarms(:precip_3h_belem),
      trigger_state: "alarm",
      action_type: "notification",
      configuration: { "channels" => ["websocket"] }
    )
    assert action.valid?
  end

  test "invalid without alarm" do
    action = alarm_actions(:precip_alarm_websocket)
    action.alarm = nil
    assert_not action.valid?
  end

  test "invalid without trigger_state" do
    action = alarm_actions(:precip_alarm_websocket)
    action.trigger_state = nil
    assert_not action.valid?
  end

  test "invalid with unknown trigger_state" do
    action = alarm_actions(:precip_alarm_websocket)
    action.trigger_state = "critical"
    assert_not action.valid?
    assert_includes action.errors[:trigger_state], "is not included in the list"
  end

  test "invalid without action_type" do
    action = alarm_actions(:precip_alarm_websocket)
    action.action_type = nil
    assert_not action.valid?
  end

  test "invalid with unknown action_type" do
    action = alarm_actions(:precip_alarm_websocket)
    action.action_type = "siren"
    assert_not action.valid?
    assert_includes action.errors[:action_type], "is not included in the list"
  end

  # ── Scopes ──

  test "enabled scope returns only enabled actions" do
    enabled = AlarmAction.enabled
    assert_includes enabled, alarm_actions(:precip_alarm_websocket)
    assert_not_includes enabled, alarm_actions(:disabled_action)
  end

  test "for_state scope filters by trigger_state" do
    alarm_state_actions = AlarmAction.for_state("alarm")
    assert_includes alarm_state_actions, alarm_actions(:precip_alarm_websocket)
    assert_not_includes alarm_state_actions, alarm_actions(:precip_ok_websocket)
  end

  # ── Associations ──

  test "belongs to alarm" do
    assert_equal alarms(:precip_3h_belem), alarm_actions(:precip_alarm_websocket).alarm
  end
end
