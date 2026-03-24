require "test_helper"

class Admin::SensorStationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_sensor_stations_path
    assert_response :success
  end

  test "index displays sensor station names" do
    get admin_sensor_stations_path
    assert_select "td", text: /Pluviômetro Centro/
    assert_select "td", text: /Fluviômetro Rio Belém/
  end

  test "index shows summary cards with counts" do
    get admin_sensor_stations_path
    assert_select "[data-testid='summary-total-count']"
    assert_select "[data-testid='summary-online-count']"
    assert_select "[data-testid='summary-maintenance-count']"
  end

  test "index shows station type badges" do
    get admin_sensor_stations_path
    assert_select "span", text: "Pluviômetro"
    assert_select "span", text: "Fluviômetro"
  end

  test "index shows status indicators" do
    get admin_sensor_stations_path
    assert_select "span", text: "Ativo"
    assert_select "span", text: "Manutenção"
  end

  test "index shows empty state when no stations exist" do
    SensorStation.destroy_all
    get admin_sensor_stations_path
    assert_select "div", text: /Nenhuma estação cadastrada/
  end

  # ── Show ──

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
