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

  # ── Per-chart date-range pickers ──

  test "show renders a turbo frame for each range-driven chart" do
    get admin_weather_path
    assert_select "turbo-frame#weather_forecast"
    assert_select "turbo-frame#weather_comparison"
  end

  test "show renders a range form for each chart" do
    get admin_weather_path
    assert_select "input[type=datetime-local][name='forecast[from]']"
    assert_select "input[type=datetime-local][name='forecast[to]']"
    assert_select "input[type=datetime-local][name='comparison[from]']"
    assert_select "input[type=datetime-local][name='comparison[to]']"
  end

  test "show defaults to recent observations in the comparison chart" do
    get admin_weather_path
    assert_select "[data-testid='comparison-chart']"
  end

  test "show defaults to upcoming forecasts in the forecast chart" do
    get admin_weather_path
    assert_select "[data-testid='forecast-chart']"
  end

  test "comparison range with no data shows the empty state" do
    get admin_weather_path, params: { comparison: { from: 10.days.ago.iso8601, to: 9.days.ago.iso8601 } }
    assert_response :success
    assert_select "[data-testid='comparison-empty']"
    assert_select "[data-testid='comparison-chart']", count: 0
  end

  test "forecast range with no data shows the empty state" do
    get admin_weather_path, params: { forecast: { from: 5.days.from_now.iso8601, to: 6.days.from_now.iso8601 } }
    assert_response :success
    assert_select "[data-testid='forecast-empty']"
    assert_select "[data-testid='forecast-chart']", count: 0
  end

  test "accepts a future comparison range" do
    get admin_weather_path, params: { comparison: { from: 1.day.from_now.iso8601, to: 2.days.from_now.iso8601 } }
    assert_response :success
  end

  test "accepts a past forecast range" do
    get admin_weather_path, params: { forecast: { from: 10.hours.ago.iso8601, to: 1.hour.ago.iso8601 } }
    assert_response :success
    assert_select "[data-testid='forecast-chart']"
  end

  test "invalid datetime params fall back to defaults" do
    get admin_weather_path, params: { comparison: { from: "not-a-date", to: "garbage" } }
    assert_response :success
    assert_select "[data-testid='comparison-chart']"
  end

  test "reversed range is tolerated by swapping bounds" do
    get admin_weather_path, params: { comparison: { from: Time.current.iso8601, to: 24.hours.ago.iso8601 } }
    assert_response :success
    assert_select "[data-testid='comparison-chart']"
  end

  # ── Overlap semantics + picker bounds ──

  test "default forecast window includes an in-progress bucket via overlap" do
    get admin_weather_path
    el = css_select("[data-admin--source-switcher-sources-value]").first
    data = JSON.parse(el["data-admin--source-switcher-sources-value"])
    labels = data.values.flatten.map { |f| f["time"] }
    # valid_from is 1h in the past but the bucket is still valid now, so a
    # now-anchored window must still include it.
    in_progress = weather_forecasts(:open_meteo_current)
    assert_includes labels, in_progress.valid_from.strftime("%d/%m %H:%M")
  end

  test "forecast range inputs are bounded to the available data extent" do
    get admin_weather_path
    assert_select "input[name='forecast[from]'][min][max]"
    assert_select "input[name='forecast[to]'][min][max]"
  end

  test "comparison range inputs are bounded to the available data extent" do
    get admin_weather_path
    assert_select "input[name='comparison[from]'][min][max]"
    assert_select "input[name='comparison[to]'][min][max]"
  end
end
