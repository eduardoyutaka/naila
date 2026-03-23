require "test_helper"

class Admin::SensorStationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "show renders successfully" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_response :success
  end

  test "show contains turbo frame for side sheet extraction" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail"
  end

  test "show displays sensor name" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "h2", text: /Pluviômetro Centro/
    end
  end

  test "show renders precipitation chart for pluviometer" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-precipitation']"
    end
  end

  test "show does not render precipitation chart for river gauge" do
    get admin_sensor_station_path(sensor_stations(:fluv_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-precipitation']", count: 0
    end
  end

  test "show renders river level chart for river gauge" do
    get admin_sensor_station_path(sensor_stations(:fluv_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-river_level']"
    end
  end

  test "show does not render river level chart for pluviometer" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-river_level']", count: 0
    end
  end

  test "show renders temperature chart for weather station" do
    get admin_sensor_station_path(sensor_stations(:meteo_batel))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-temperature']"
    end
  end
end
