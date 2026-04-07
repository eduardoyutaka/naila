require "test_helper"

class Admin::Alarms::StatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "update enables a disabled alarm" do
    alarm = alarms(:disabled_alarm)
    assert_not alarm.enabled?
    patch admin_alarm_status_path(alarm), params: { enabled: "true" }
    assert_redirected_to admin_alarm_path(alarm)
    assert alarm.reload.enabled?
  end

  test "update disables an enabled alarm" do
    alarm = alarms(:precip_3h_belem)
    assert alarm.enabled?
    patch admin_alarm_status_path(alarm), params: { enabled: "false" }
    assert_redirected_to admin_alarm_path(alarm)
    assert_not alarm.reload.enabled?
  end

  test "operator cannot update alarm status" do
    sign_in_as users(:operator)
    patch admin_alarm_status_path(alarms(:disabled_alarm)), params: { enabled: "true" }
    assert_redirected_to admin_root_path
  end
end
