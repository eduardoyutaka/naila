require "test_helper"

class Admin::AlarmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Authentication ──

  test "index requires authentication" do
    reset!
    get admin_alarms_path
    assert_redirected_to login_path
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_alarms_path
    assert_response :success
  end

  test "index displays alarm names" do
    get admin_alarms_path
    assert_select "td", text: /Precipitação 3h Bacia Belém/
  end

  test "index shows summary cards" do
    get admin_alarms_path
    assert_select "[data-testid='summary-total']"
    assert_select "[data-testid='summary-enabled']"
    assert_select "[data-testid='summary-alarm']"
  end

  test "index shows state badges" do
    get admin_alarms_path
    assert_select "span", text: "OK"
    assert_select "span", text: "Alarme"
  end

  test "index shows empty state when no alarms exist" do
    Alarm.destroy_all
    get admin_alarms_path
    assert_select "div", text: /Nenhum alarme cadastrado/
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

  test "show displays alarm name and state" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "h1", text: /Precipitação 3h Bacia Belém/
    assert_select "[data-testid='alarm-state']", text: "OK"
  end

  test "show displays configuration section" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "[data-testid='alarm-config']"
  end

  test "show displays actions section" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "[data-testid='alarm-actions']"
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_alarm_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_alarm_path
    assert_select "form" do
      assert_select "input[name='alarm[name]']"
      assert_select "input[name='alarm[alarm_type]'][value='metric']"
    end
  end

  # ── Create ──

  test "create with valid params creates alarm and redirects" do
    assert_difference "Alarm.count", 1 do
      post admin_alarms_path, params: {
        alarm: {
          name: "Novo Alarme Teste",
          alarm_type: "metric",
          enabled: true,
          metric_name: "precipitation_1h",
          statistic: "Sum",
          period_seconds: 3600,
          evaluation_periods: 1,
          datapoints_to_alarm: 1,
          missing_data_treatment: "missing",
          alarm_thresholds_attributes: {
            "0" => { severity: 2, comparison_operator: "GreaterThanThreshold", threshold_value: 50.0, unit: "mm" }
          }
        }
      }
    end
    assert_redirected_to admin_alarm_path(Alarm.last)
    assert_equal 1, Alarm.last.alarm_thresholds.count
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "Alarm.count" do
      post admin_alarms_path, params: {
        alarm: { name: "", alarm_type: "metric" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create alarms" do
    sign_in_as users(:operator)
    post admin_alarms_path, params: {
      alarm: { name: "Proibido", alarm_type: "metric" }
    }
    assert_redirected_to admin_root_path
  end

  test "coordinator can create alarms" do
    sign_in_as users(:coordinator)
    assert_difference "Alarm.count", 1 do
      post admin_alarms_path, params: {
        alarm: {
          name: "Alarme do Coordenador",
          alarm_type: "metric",
          metric_name: "precipitation_1h",
          statistic: "Sum",
          period_seconds: 3600,
          evaluation_periods: 1,
          datapoints_to_alarm: 1,
          missing_data_treatment: "missing",
          alarm_thresholds_attributes: {
            "0" => { severity: 1, comparison_operator: "GreaterThanThreshold", threshold_value: 10.0, unit: "mm" }
          }
        }
      }
    end
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    get edit_admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

  test "update with valid params updates alarm and redirects" do
    alarm = alarms(:precip_3h_belem)
    patch admin_alarm_path(alarm), params: {
      alarm: { name: "Alarme Atualizado" }
    }
    assert_redirected_to admin_alarm_path(alarm)
    assert_equal "Alarme Atualizado", alarm.reload.name
  end

  test "operator cannot update alarms" do
    sign_in_as users(:operator)
    patch admin_alarm_path(alarms(:precip_3h_belem)), params: {
      alarm: { name: "Tentativa" }
    }
    assert_redirected_to admin_root_path
  end

  # ── Destroy ──

  test "admin can destroy alarm" do
    alarm = alarms(:disabled_alarm)
    assert_difference "Alarm.count", -1 do
      delete admin_alarm_path(alarm)
    end
    assert_redirected_to admin_alarms_path
  end

  test "operator cannot destroy alarms" do
    sign_in_as users(:operator)
    assert_no_difference "Alarm.count" do
      delete admin_alarm_path(alarms(:disabled_alarm))
    end
    assert_redirected_to admin_root_path
  end

  test "coordinator cannot destroy alarms" do
    sign_in_as users(:coordinator)
    assert_no_difference "Alarm.count" do
      delete admin_alarm_path(alarms(:disabled_alarm))
    end
    assert_redirected_to admin_root_path
  end

  # ── History ──

  test "history renders successfully" do
    get history_admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

end
