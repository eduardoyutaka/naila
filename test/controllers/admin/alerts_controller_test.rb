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
end
