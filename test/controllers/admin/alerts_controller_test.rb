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
end
