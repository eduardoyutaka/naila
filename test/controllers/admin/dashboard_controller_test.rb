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
    assert_includes sensor_names, "Pluviômetro Centro"
    assert_includes sensor_names, "Fluviômetro Rio Belém"
    assert_not_includes sensor_names, "Pluviômetro Desativado"
  end

  test "dashboard sensor data contains required fields" do
    get admin_root_path
    sensor_json = css_select("[data-admin--map-sensors-value]").first["data-admin--map-sensors-value"]
    sensors = JSON.parse(sensor_json)
    sensor = sensors.find { |s| s["name"] == "Pluviômetro Centro" }

    assert_not_nil sensor
    assert_equal "pluviometer", sensor["station_type"]
    assert_equal "active", sensor["status"]
    assert_in_delta(-25.4284, sensor["lat"], 0.001)
    assert_in_delta(-49.2733, sensor["lng"], 0.001)
    assert_equal "Centro", sensor["neighborhood"]
  end
end
