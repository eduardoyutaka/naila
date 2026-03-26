require "test_helper"

class Admin::AlertThresholdsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Authentication ──

  test "index requires authentication" do
    reset!
    get admin_alert_thresholds_path
    assert_redirected_to login_path
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_alert_thresholds_path
    assert_response :success
  end

  test "index displays threshold parameter and value" do
    get admin_alert_thresholds_path
    assert_select "td", text: /Precipitação/
    assert_select "td", text: /Nível do Rio/
  end

  test "index shows summary cards" do
    get admin_alert_thresholds_path
    assert_select "div", text: /Total de Limiares/
    assert_select "div", text: /Limiares Ativos/
  end

  test "index shows new threshold button for coordinator" do
    sign_in_as users(:coordinator)
    get admin_alert_thresholds_path
    assert_select "a[href='#{new_admin_alert_threshold_path}']", text: /Novo Limiar/
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_alert_threshold_path(alert_thresholds(:precipitation_high))
    assert_response :success
  end

  test "show displays threshold details" do
    threshold = alert_thresholds(:precipitation_high)
    get admin_alert_threshold_path(threshold)
    assert_select "h1", text: /Precipitação/
    assert_select "span", text: /#{threshold.value}/
  end

  test "show displays linked alerts section" do
    get admin_alert_threshold_path(alert_thresholds(:precipitation_high))
    assert_select "h2", text: /Alertas Disparados/
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_alert_threshold_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_alert_threshold_path
    assert_select "form" do
      assert_select "select[name='alert_threshold[parameter]']"
      assert_select "select[name='alert_threshold[threshold_type]']"
      assert_select "input[name='alert_threshold[value]']"
      assert_select "select[name='alert_threshold[unit]']"
      assert_select "select[name='alert_threshold[comparison]']"
      assert_select "select[name='alert_threshold[severity]']"
    end
  end

  # ── Create ──

  test "create with valid params creates threshold and redirects" do
    assert_difference "AlertThreshold.count", 1 do
      post admin_alert_thresholds_path, params: {
        alert_threshold: {
          parameter: "river_level",
          threshold_type: "instant",
          severity: 2,
          value: 2.0,
          unit: "m",
          comparison: "gte",
          cooldown_minutes: 60
        }
      }
    end
    assert_redirected_to admin_alert_threshold_path(AlertThreshold.last)
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "AlertThreshold.count" do
      post admin_alert_thresholds_path, params: {
        alert_threshold: { parameter: "", value: nil, severity: nil }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create thresholds" do
    sign_in_as users(:operator)
    post admin_alert_thresholds_path, params: {
      alert_threshold: {
        parameter: "river_level",
        threshold_type: "instant",
        severity: 2,
        value: 2.0,
        unit: "m",
        comparison: "gte",
        cooldown_minutes: 60
      }
    }
    assert_redirected_to admin_root_path
  end

  # ── Edit ──

  test "edit renders successfully" do
    get edit_admin_alert_threshold_path(alert_thresholds(:precipitation_high))
    assert_response :success
  end

  test "edit displays form with existing values" do
    threshold = alert_thresholds(:precipitation_high)
    get edit_admin_alert_threshold_path(threshold)
    assert_select "input[name='alert_threshold[value]'][value='#{threshold.value}']"
  end

  # ── Update ──

  test "update with valid params saves and redirects" do
    threshold = alert_thresholds(:precipitation_high)
    patch admin_alert_threshold_path(threshold), params: {
      alert_threshold: { value: 75.0 }
    }
    assert_redirected_to admin_alert_threshold_path(threshold)
    assert_equal 75.0, threshold.reload.value
  end

  test "update with invalid params renders edit with 422" do
    threshold = alert_thresholds(:precipitation_high)
    patch admin_alert_threshold_path(threshold), params: {
      alert_threshold: { severity: 99 }
    }
    assert_response :unprocessable_entity
  end

  test "operator cannot update thresholds" do
    sign_in_as users(:operator)
    patch admin_alert_threshold_path(alert_thresholds(:precipitation_high)), params: {
      alert_threshold: { value: 99.0 }
    }
    assert_redirected_to admin_root_path
  end

  # ── Destroy ──

  test "admin can destroy threshold" do
    threshold = alert_thresholds(:precipitation_high)
    assert_difference "AlertThreshold.count", -1 do
      delete admin_alert_threshold_path(threshold)
    end
    assert_redirected_to admin_alert_thresholds_path
  end

  test "coordinator cannot destroy threshold" do
    sign_in_as users(:coordinator)
    delete admin_alert_threshold_path(alert_thresholds(:precipitation_high))
    assert_redirected_to admin_root_path
  end

  test "operator cannot destroy threshold" do
    sign_in_as users(:operator)
    delete admin_alert_threshold_path(alert_thresholds(:precipitation_high))
    assert_redirected_to admin_root_path
  end
end
