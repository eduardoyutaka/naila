require "test_helper"

class Public::AlarmsControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully" do
    get public_alarms_path
    assert_response :success
  end

  test "index shows active alarms section" do
    get public_alarms_path
    assert_select "[data-testid='active-alarms']"
  end

  test "index shows resolved alarms section" do
    get public_alarms_path
    assert_select "[data-testid='resolved-alarms']"
  end

  test "index displays alarm cards for in-alarm state" do
    alarm = alarms(:precip_3h_belem)
    alarm.update_columns(state: "alarm", state_changed_at: Time.current)

    get public_alarms_path
    assert_select "[data-testid='alarm-card']"
  end

  test "index shows empty state when no active alarms" do
    Alarm.update_all(state: "ok")

    get public_alarms_path
    assert_response :success
    assert_select "[data-testid='active-alarms']"
  end
end
