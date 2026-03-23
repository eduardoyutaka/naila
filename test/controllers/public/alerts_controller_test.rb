require "test_helper"

class Public::AlertsControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully without authentication" do
    get public_alerts_path
    assert_response :success
  end

  test "index displays active alerts" do
    get public_alerts_path
    assert_select "[data-testid='active-alerts']" do
      assert_select "[data-testid='alert-card']", minimum: 1
    end
  end

  test "index displays alert severity" do
    get public_alerts_path
    assert_select "[data-testid='alert-card']" do
      assert_select "[data-testid='alert-severity']"
    end
  end

  test "index displays recently resolved alerts section" do
    get public_alerts_path
    assert_select "[data-testid='resolved-alerts']"
  end
end
