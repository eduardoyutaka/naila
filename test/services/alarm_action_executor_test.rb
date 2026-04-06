require "test_helper"

class AlarmActionExecutorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    # Use disabled_alarm as base since it has no parent composite (no suppression)
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

  test "creates alert for alarm state transition" do
    assert_difference "Alert.count", 1 do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end

    alert = @alarm.alerts.order(:created_at).last
    assert_equal "automatic", alert.alert_type
    assert_equal "active", alert.status
    assert_equal @alarm.severity, alert.severity
    assert_equal @alarm, alert.alarm
    assert_equal "alarm", alert.alarm_state
  end

  test "creates alert notifications for each configured channel" do
    assert_difference "AlertNotification.count", 2 do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "enqueues SendAlertNotificationJob for each notification" do
    assert_enqueued_jobs 2, only: SendAlertNotificationJob do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "skips disabled actions" do
    @alarm.alarm_actions.update_all(enabled: false)

    assert_no_difference "Alert.count" do
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

    assert_difference "Alert.count", 1 do
      AlarmActionExecutor.execute(@alarm, "ok")
    end

    alert = @alarm.alerts.last
    assert_equal "ok", alert.alarm_state
  end

  test "executes insufficient_data state actions" do
    @alarm.alarm_actions.create!(
      trigger_state: "insufficient_data",
      action_type: "notification",
      configuration: { "channels" => %w[websocket] },
      enabled: true
    )

    assert_difference "Alert.count", 1 do
      AlarmActionExecutor.execute(@alarm, "insufficient_data")
    end

    alert = @alarm.alerts.last
    assert_equal "insufficient_data", alert.alarm_state
  end

  # ── Suppression ──

  test "does not execute actions when alarm is suppressed by parent composite" do
    # precip_3h_belem is a child of composite_flood_belem which has suppress_child_actions=true
    alarm = alarms(:precip_3h_belem)

    assert_no_difference "Alert.count" do
      AlarmActionExecutor.execute(alarm, "alarm")
    end
  end

  test "executes actions when parent composite does not suppress" do
    composite = alarms(:composite_flood_belem)
    composite.update!(suppress_child_actions: false)

    alarm = alarms(:precip_3h_belem)

    assert_difference "Alert.count", 1 do
      AlarmActionExecutor.execute(alarm, "alarm")
    end
  end
end
