require "test_helper"

class Admin::Alarms::AcknowledgmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:coordinator)
  end

  test "update acknowledges a firing alarm as the signed-in user" do
    alarm = alarms(:flood_alert_belem) # state: alarm

    patch admin_alarm_acknowledgment_path(alarm), params: { acknowledged: "true" }

    assert_redirected_to admin_alarm_path(alarm)
    alarm.reload
    assert alarm.acknowledged?
    assert_equal users(:coordinator), alarm.acknowledged_by
  end

  test "update removes acknowledgment" do
    alarm = alarms(:flood_alert_belem)
    alarm.acknowledge!(users(:coordinator))

    patch admin_alarm_acknowledgment_path(alarm), params: { acknowledged: "false" }

    assert_redirected_to admin_alarm_path(alarm)
    assert_not alarm.reload.acknowledged?
  end

  test "operator cannot acknowledge an alarm" do
    sign_in_as users(:operator)
    alarm = alarms(:flood_alert_belem)

    patch admin_alarm_acknowledgment_path(alarm), params: { acknowledged: "true" }

    assert_redirected_to admin_root_path
    assert_not alarm.reload.acknowledged?
  end

  test "unauthenticated request is redirected to login" do
    reset!
    patch admin_alarm_acknowledgment_path(alarms(:flood_alert_belem)), params: { acknowledged: "true" }
    assert_redirected_to login_path
  end
end
