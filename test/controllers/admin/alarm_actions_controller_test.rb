require "test_helper"

class Admin::AlarmActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @alarm = alarms(:precip_3h_belem)
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_alarm_alarm_action_path(@alarm)
    assert_response :success
  end

  test "new form's min_severity dropdown labels severity 3 consistently as Alarme, not Alto" do
    get new_admin_alarm_alarm_action_path(@alarm)
    assert_select "select[name='alarm_action[min_severity]']" do
      assert_select "option", text: "3 — Alarme"
      assert_select "option", text: "3 — Alto", count: 0
    end
  end

  # ── Create ──

  test "create with valid params creates action and redirects" do
    assert_difference "AlarmAction.count", 1 do
      post admin_alarm_alarm_actions_path(@alarm), params: {
        alarm_action: {
          trigger_state: "insufficient_data",
          action_type: "notification"
        }
      }
    end
    assert_redirected_to admin_alarm_path(@alarm)
  end

  test "create with min_severity on a non-alarm trigger renders new with 422" do
    assert_no_difference "AlarmAction.count" do
      post admin_alarm_alarm_actions_path(@alarm), params: {
        alarm_action: { trigger_state: "ok", action_type: "notification", min_severity: 2 }
      }
    end
    assert_response :unprocessable_entity
    assert_select "*", text: /só se aplica quando o gatilho é Alarme/
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "AlarmAction.count" do
      post admin_alarm_alarm_actions_path(@alarm), params: {
        alarm_action: { trigger_state: "", action_type: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create alarm actions" do
    sign_in_as users(:operator)
    assert_no_difference "AlarmAction.count" do
      post admin_alarm_alarm_actions_path(@alarm), params: {
        alarm_action: { trigger_state: "alarm", action_type: "notification" }
      }
    end
    assert_redirected_to admin_root_path
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    action = alarm_actions(:precip_alarm_websocket)
    get edit_admin_alarm_alarm_action_path(@alarm, action)
    assert_response :success
  end

  test "update with valid params updates action and redirects" do
    action = alarm_actions(:precip_alarm_websocket)
    patch admin_alarm_alarm_action_path(@alarm, action), params: {
      alarm_action: { min_severity: 3 }
    }
    assert_redirected_to admin_alarm_path(@alarm)
    assert_equal 3, action.reload.min_severity
  end

  # ── Destroy ──

  test "admin can destroy alarm action" do
    action = alarm_actions(:precip_alarm_websocket)
    assert_difference "AlarmAction.count", -1 do
      delete admin_alarm_alarm_action_path(@alarm, action)
    end
    assert_redirected_to admin_alarm_path(@alarm)
  end

  test "operator cannot destroy alarm actions" do
    sign_in_as users(:operator)
    action = alarm_actions(:precip_alarm_websocket)
    assert_no_difference "AlarmAction.count" do
      delete admin_alarm_alarm_action_path(@alarm, action)
    end
    assert_redirected_to admin_root_path
  end
end
