require "test_helper"

class Admin::AlertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Authentication ──

  test "index requires authentication" do
    reset!
    get admin_alerts_path
    assert_redirected_to login_path
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_alerts_path
    assert_response :success
  end

  test "index displays alert titles" do
    get admin_alerts_path
    assert_select "td", text: /Risco de transbordamento no Rio Belém/
  end

  test "index displays summary cards" do
    get admin_alerts_path
    assert_select "[data-testid='summary-active-count']"
    assert_select "[data-testid='summary-unacknowledged-count']"
  end

  test "index shows severity badges" do
    get admin_alerts_path
    assert_select ".bg-risk-high\\/20"
  end

  test "index shows new alert button" do
    get admin_alerts_path
    assert_select "a[href='#{new_admin_alert_path}']", text: /Novo Alerta/
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_alert_path(alerts(:active_high))
    assert_response :success
  end

  test "show displays alert title and description" do
    get admin_alert_path(alerts(:active_high))
    assert_select "h1", text: /Risco de transbordamento no Rio Belém/
    assert_select "p", text: /Nível do Rio Belém acima do limiar/
  end

  test "show displays instructions when present" do
    get admin_alert_path(alerts(:active_high))
    assert_select "[data-testid='alert-instructions']", text: /Evacuar áreas ribeirinhas/
  end

  test "show displays notifications list" do
    get admin_alert_path(alerts(:active_high))
    assert_select "[data-testid='notifications-list']"
  end

  test "show displays acknowledge button for active alert" do
    get admin_alert_path(alerts(:active_high))
    assert_select "form[action='#{acknowledge_admin_alert_path(alerts(:active_high))}']"
  end

  test "show does not display acknowledge button for resolved alert" do
    get admin_alert_path(alerts(:resolved_alert))
    assert_select "form[action='#{acknowledge_admin_alert_path(alerts(:resolved_alert))}']", count: 0
  end

  test "show displays resolve button for active alert" do
    get admin_alert_path(alerts(:active_high))
    assert_select "form[action='#{resolve_admin_alert_path(alerts(:active_high))}']"
  end

  test "show does not display resolve button for resolved alert" do
    get admin_alert_path(alerts(:resolved_alert))
    assert_select "form[action='#{resolve_admin_alert_path(alerts(:resolved_alert))}']", count: 0
  end

  test "show displays thresholds section with related thresholds" do
    get admin_alert_path(alerts(:active_high))
    assert_select "[data-testid='thresholds-section']"
    assert_select "[data-testid='thresholds-section'] table tbody tr"
  end

  test "show displays new threshold button for coordinator" do
    sign_in_as users(:coordinator)
    alert = alerts(:active_high)
    get admin_alert_path(alert)
    assert_select "[data-testid='thresholds-section'] a[href*='#{new_admin_alert_threshold_path}']", text: /Novo Limiar/
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_alert_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_alert_path
    assert_select "form" do
      assert_select "input[name='alert[title]']"
      assert_select "textarea[name='alert[description]']"
      assert_select "select[name='alert[severity]']"
      assert_select "textarea[name='alert[instructions]']"
    end
  end

  # ── Create ──

  test "create with valid params creates alert and redirects" do
    assert_difference "Alert.count", 1 do
      post admin_alerts_path, params: {
        alert: {
          title: "Novo alerta manual",
          description: "Descrição do novo alerta.",
          severity: 2
        }
      }
    end
    assert_redirected_to admin_alert_path(Alert.last)
  end

  test "create sets alert_type to manual, status to active, and created_by" do
    post admin_alerts_path, params: {
      alert: {
        title: "Alerta manual",
        description: "Teste de criação.",
        severity: 1
      }
    }
    alert = Alert.last
    assert_equal "manual", alert.alert_type
    assert_equal "active", alert.status
    assert_equal users(:admin), alert.created_by
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "Alert.count" do
      post admin_alerts_path, params: {
        alert: { title: "", description: "", severity: nil }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create alerts" do
    sign_in_as users(:operator)
    post admin_alerts_path, params: {
      alert: {
        title: "Alerta proibido",
        description: "Operador tentando criar.",
        severity: 1
      }
    }
    assert_redirected_to admin_root_path
  end

  # ── Acknowledge ──

  test "acknowledge changes status and redirects" do
    alert = alerts(:active_high)
    patch acknowledge_admin_alert_path(alert)
    assert_redirected_to admin_alert_path(alert)

    alert.reload
    assert_equal "acknowledged", alert.status
    assert_not_nil alert.acknowledged_at
  end

  test "operator can acknowledge alerts" do
    sign_in_as users(:operator)
    alert = alerts(:active_attention)
    patch acknowledge_admin_alert_path(alert)
    assert_redirected_to admin_alert_path(alert)

    alert.reload
    assert_equal "acknowledged", alert.status
  end

  # ── Resolve ──

  test "resolve changes status and sets resolved_by" do
    alert = alerts(:active_high)
    patch resolve_admin_alert_path(alert)
    assert_redirected_to admin_alert_path(alert)

    alert.reload
    assert_equal "resolved", alert.status
    assert_equal users(:admin), alert.resolved_by
    assert_not_nil alert.resolved_at
  end

  test "coordinator can resolve alerts" do
    sign_in_as users(:coordinator)
    alert = alerts(:active_attention)
    patch resolve_admin_alert_path(alert)
    assert_redirected_to admin_alert_path(alert)

    alert.reload
    assert_equal "resolved", alert.status
  end

  test "operator cannot resolve alerts" do
    sign_in_as users(:operator)
    patch resolve_admin_alert_path(alerts(:active_high))
    assert_redirected_to admin_root_path
  end
end
