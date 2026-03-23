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

  test "show displays recent readings" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='readings-list']"
    end
  end

  test "show renders precipitation chart for station with precipitation data" do
    get admin_sensor_station_path(sensor_stations(:pluv_centro))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='precipitation-chart']"
    end
  end

  test "show does not render precipitation chart for station without precipitation data" do
    get admin_sensor_station_path(sensor_stations(:fluv_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='precipitation-chart']", count: 0
    end
  end
end
