require "test_helper"

class AlarmActionExecutorTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @alarm = alarms(:disabled_alarm)
    @alarm.update!(enabled: true)
    @alarm.alarm_actions.create!(
      trigger_state: "alarm",
      action_type: "notification",
      configuration: { "channels" => %w[websocket sms] },
      enabled: true
    )
  end

  # ── Notification actions ──

  test "broadcasts to alarms ActionCable channel on notification action" do
    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "broadcast payload contains alarm state info" do
    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end

    payload = ActiveSupport::JSON.decode(broadcasts("alarms").last)
    assert_equal "alarm_state_change", payload["event_type"]
    assert_equal @alarm.id, payload["alarm_id"]
    assert_equal "alarm", payload["state"]
    assert_nil payload["current_severity"]  # disabled_alarm has no current_severity
  end

  test "skips disabled actions" do
    @alarm.alarm_actions.update_all(enabled: false)

    assert_no_broadcasts("alarms") do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes ok state actions" do
    @alarm.alarm_actions.create!(
      trigger_state: "ok",
      action_type: "notification",
      configuration: { "channels" => %w[websocket] },
      enabled: true
    )

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "ok")
    end
  end

  test "executes insufficient_data state actions" do
    @alarm.alarm_actions.create!(
      trigger_state: "insufficient_data",
      action_type: "notification",
      configuration: { "channels" => %w[websocket] },
      enabled: true
    )

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "insufficient_data")
    end
  end

  # ── min_severity filtering ──

  test "skips action when current_severity is below min_severity" do
    @alarm.update!(current_severity: 1)
    @alarm.alarm_actions.update_all(min_severity: 2)

    assert_no_broadcasts("alarms") do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes action when current_severity meets min_severity" do
    @alarm.update!(current_severity: 2)
    @alarm.alarm_actions.update_all(min_severity: 2)

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes action with no min_severity regardless of current_severity" do
    @alarm.update!(current_severity: 1)
    # min_severity is nil by default

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  # ── Suppression ──

  test "does not broadcast when alarm is suppressed by parent composite" do
    alarm = alarms(:precip_3h_belem)

    assert_no_broadcasts("alarms") do
      AlarmActionExecutor.execute(alarm, "alarm")
    end
  end

  test "broadcasts when parent composite does not suppress" do
    composite = alarms(:composite_flood_belem)
    composite.update!(suppress_child_actions: false)
    alarm = alarms(:precip_3h_belem)

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(alarm, "alarm")
    end
  end
end
