require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "dashboard index loads successfully" do
    get admin_root_path
    assert_response :success
  end

  test "dashboard passes sensor stations data to map" do
    get admin_root_path
    assert_response :success
    assert_select "[data-admin--map-sensors-value]"
  end

  test "dashboard sensor data includes only stations with location" do
    get admin_root_path
    sensor_json = css_select("[data-admin--map-sensors-value]").first["data-admin--map-sensors-value"]
    sensors = JSON.parse(sensor_json)

    sensor_names = sensors.map { |s| s["name"] }
    assert_includes sensor_names, "Estação Belém — Centro Cívico"
    assert_includes sensor_names, "Estação Barigui — Parque Barigui"
  end

  test "dashboard shows weather summary section" do
    get admin_root_path
    assert_response :success
    assert_select "[data-testid='weather-summary']"
  end

  test "dashboard weather summary shows forecast precipitation" do
    get admin_root_path
    assert_select "[data-testid='forecast-precipitation']"
  end

  test "dashboard sensor data contains required fields" do
    get admin_root_path
    sensor_json = css_select("[data-admin--map-sensors-value]").first["data-admin--map-sensors-value"]
    sensors = JSON.parse(sensor_json)
    station = sensors.find { |s| s["name"] == "Estação Belém — Centro Cívico" }

    assert_not_nil station
    assert_includes station["sensor_types"], "pluviometer"
    assert_includes station["sensor_types"], "river_gauge"
    assert_equal "active", station["status"]
    assert_in_delta(-25.405, station["lat"], 0.01)
    assert_in_delta(-49.270, station["lng"], 0.01)
    assert_equal "Centro", station["neighborhood"]
  end
end
