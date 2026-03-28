require "test_helper"

class Admin::WeatherControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "show loads successfully" do
    get admin_weather_path
    assert_response :success
  end

  test "show displays current conditions section" do
    get admin_weather_path
    assert_select "[data-testid='current-conditions']"
  end

  test "show displays data source health section" do
    get admin_weather_path
    assert_select "[data-testid='data-source-health']"
  end

  test "show requires authentication" do
    reset!
    get admin_weather_path
    assert_redirected_to login_path
  end

  test "operator can view weather page" do
    sign_in_as users(:operator)
    get admin_weather_path
    assert_response :success
  end

  test "coordinator can view weather page" do
    sign_in_as users(:coordinator)
    get admin_weather_path
    assert_response :success
  end
end
