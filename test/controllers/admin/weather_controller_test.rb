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

  test "data sources card is rendered above current conditions" do
    get admin_weather_path
    assert_operator response.body.index('data-testid="data-source-health"'),
                     :<,
                     response.body.index('data-testid="current-conditions"')
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
    get admin_weather_path, params: { forecast_source: "open_meteo" }
    el = css_select("[data-admin--forecast-chart-forecasts-value]").first
    data = JSON.parse(el["data-admin--forecast-chart-forecasts-value"])
    labels = data.map { |f| f["time"] }
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

  # ── "Aplicar" is never blocked by out-of-bounds defaults (Bug A) ──

  test "range defaults stay within the pickers' min/max bounds" do
    get admin_weather_path

    forecast_to = css_select("input[name='forecast[to]']").first
    assert_operator forecast_to["value"], :<=, forecast_to["max"],
      "default forecast end must not overflow the picker max, or Aplicar is blocked"

    forecast_from = css_select("input[name='forecast[from]']").first
    assert_operator forecast_from["value"], :>=, forecast_from["min"]

    comparison_from = css_select("input[name='comparison[from]']").first
    assert_operator comparison_from["value"], :>=, comparison_from["min"],
      "default comparison start must not underflow the picker min, or Aplicar is blocked"

    comparison_to = css_select("input[name='comparison[to]']").first
    assert_operator comparison_to["value"], :<=, comparison_to["max"]
  end

  # ── Forecast source is a real, persistent, always-visible control (Bugs B/C/D) ──

  test "forecast source is echoed back as the selected option and drives the chart" do
    get admin_weather_path, params: {
      forecast_source: "open_meteo",
      forecast: { from: 2.hours.ago.iso8601, to: 5.hours.from_now.iso8601 }
    }
    assert_response :success
    assert_select "select[name=forecast_source] option[selected][value=?]", "open_meteo"

    el = css_select("[data-admin--forecast-chart-forecasts-value]").first
    refute_nil el, "forecast chart should render for the selected source"
    labels = JSON.parse(el["data-admin--forecast-chart-forecasts-value"]).map { |f| f["time"] }
    assert_includes labels, weather_forecasts(:open_meteo_current).valid_from.strftime("%d/%m %H:%M")
    refute_includes labels, weather_forecasts(:owm_future).valid_from.strftime("%d/%m %H:%M"),
      "only the selected provider's forecasts should feed the chart"
  end

  test "source dropdown lists every provider even when only one has data in range" do
    # This window overlaps only the Open-Meteo expired bucket; OWM has nothing here.
    get admin_weather_path, params: { forecast: { from: 6.hours.ago.iso8601, to: 3.hours.ago.iso8601 } }
    assert_response :success
    assert_select "select[name=forecast_source] option", count: 2
    assert_select "select[name=forecast_source] option[value=?]", "open_weather_map"
    assert_select "select[name=forecast_source] option[value=?]", "open_meteo"
  end

  test "selecting a provider with no data in the range shows the empty state but keeps the dropdown" do
    get admin_weather_path, params: {
      forecast_source: "open_weather_map",
      forecast: { from: 6.hours.ago.iso8601, to: 3.hours.ago.iso8601 }
    }
    assert_response :success
    assert_select "[data-testid='forecast-empty']"
    assert_select "[data-testid='forecast-chart']", count: 0
    assert_select "select[name=forecast_source] option[selected][value=?]", "open_weather_map"
  end

  test "an invalid forecast_source falls back to a stable default" do
    get admin_weather_path, params: { forecast_source: "bogus" }
    assert_response :success
    # open_weather_map is first in FORECAST_SOURCES and has default-window data.
    assert_select "select[name=forecast_source] option[selected][value=?]", "open_weather_map"
  end
end
