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

  # ── New ──

  test "new renders successfully" do
    get new_admin_sensor_station_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_sensor_station_path
    assert_select "form" do
      assert_select "input[name='sensor_station[name]']"
      assert_select "input[name='sensor_station[external_id]']"
      assert_select "select[name='sensor_station[station_type]']"
      assert_select "input[name='sensor_station[data_source]']"
      assert_select "select[name='sensor_station[status]']"
      assert_select "input[name='sensor_station[latitude]']"
      assert_select "input[name='sensor_station[longitude]']"
      assert_select "input[name='sensor_station[elevation_m]']"
      assert_select "select[name='sensor_station[neighborhood_id]']"
      assert_select "select[name='sensor_station[drainage_basin_id]']"
      assert_select "select[name='sensor_station[river_id]']"
    end
  end

  # ── Create ──

  test "create with valid params creates station and redirects" do
    assert_difference "SensorStation.count", 1 do
      post admin_sensor_stations_path, params: {
        sensor_station: {
          name: "Nova Estação Teste",
          external_id: "TEST-001",
          station_type: "pluviometer",
          data_source: "cemaden"
        }
      }
    end
    assert_redirected_to admin_sensor_station_path(SensorStation.last)
  end

  test "create with lat/lng sets location" do
    post admin_sensor_stations_path, params: {
      sensor_station: {
        name: "Estação com Coordenadas",
        external_id: "GEO-001",
        station_type: "river_gauge",
        data_source: "ana",
        latitude: "-25.4284",
        longitude: "-49.2733"
      }
    }
    station = SensorStation.last
    assert_in_delta(-25.4284, station.location.y, 0.0001)
    assert_in_delta(-49.2733, station.location.x, 0.0001)
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "SensorStation.count" do
      post admin_sensor_stations_path, params: {
        sensor_station: { name: "", external_id: "", station_type: "", data_source: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create sensor stations" do
    sign_in_as users(:operator)
    post admin_sensor_stations_path, params: {
      sensor_station: {
        name: "Proibida",
        external_id: "NOPE-001",
        station_type: "pluviometer",
        data_source: "cemaden"
      }
    }
    assert_redirected_to admin_root_path
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
