require "test_helper"

class Admin::MonitoringStationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_monitoring_stations_path
    assert_response :success
  end

  test "index displays station names" do
    get admin_monitoring_stations_path
    assert_select "td", text: /Estação Belém/
    assert_select "td", text: /Estação Barigui/
  end

  test "index shows summary cards with counts" do
    get admin_monitoring_stations_path
    assert_select "[data-testid='summary-total-count']"
    assert_select "[data-testid='summary-online-count']"
    assert_select "[data-testid='summary-maintenance-count']"
  end

  test "index shows sensor type badges" do
    get admin_monitoring_stations_path
    assert_select "span", text: "Pluviômetro"
    assert_select "span", text: "Fluviômetro"
  end

  test "index shows status indicators" do
    get admin_monitoring_stations_path
    assert_select "span", text: "Ativo"
    assert_select "span", text: "Manutenção"
  end

  test "index shows empty state when no stations exist" do
    MonitoringStation.destroy_all
    get admin_monitoring_stations_path
    assert_select "div", text: /Nenhuma estação cadastrada/
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_monitoring_station_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_monitoring_station_path
    assert_select "form" do
      assert_select "input[name='monitoring_station[name]']"
      assert_select "input[name='monitoring_station[external_id]']"
      assert_select "input[name='monitoring_station[data_source]']"
      assert_select "select[name='monitoring_station[status]']"
      assert_select "input[name='monitoring_station[latitude]']"
      assert_select "input[name='monitoring_station[longitude]']"
      assert_select "input[name='monitoring_station[elevation_m]']"
      assert_select "select[name='monitoring_station[neighborhood_id]']"
      assert_select "select[name='monitoring_station[river_basin_id]']"
      assert_select "select[name='monitoring_station[river_id]']"
    end
  end

  test "new form does not include station_type field" do
    get new_admin_monitoring_station_path
    assert_select "select[name='monitoring_station[station_type]']", count: 0
  end

  # ── Create ──

  test "create with valid params creates station and redirects" do
    assert_difference "MonitoringStation.count", 1 do
      post admin_monitoring_stations_path, params: {
        monitoring_station: {
          name: "Nova Estação Teste",
          external_id: "TEST-001",
          data_source: "cemaden",
          river_basin_id: river_basins(:bacia_belem).id
        }
      }
    end
    assert_redirected_to admin_monitoring_station_path(MonitoringStation.last)
  end

  test "create with lat/lng sets location" do
    post admin_monitoring_stations_path, params: {
      monitoring_station: {
        name: "Estação com Coordenadas",
        external_id: "GEO-001",
        data_source: "ana",
        river_basin_id: river_basins(:bacia_belem).id,
        latitude: "-25.4284",
        longitude: "-49.2733"
      }
    }
    station = MonitoringStation.last
    assert_in_delta(-25.4284, station.location.y, 0.0001)
    assert_in_delta(-49.2733, station.location.x, 0.0001)
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "MonitoringStation.count" do
      post admin_monitoring_stations_path, params: {
        monitoring_station: { name: "", external_id: "", data_source: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create monitoring stations" do
    sign_in_as users(:operator)
    post admin_monitoring_stations_path, params: {
      monitoring_station: {
        name: "Proibida",
        external_id: "NOPE-001",
        data_source: "cemaden",
        river_basin_id: river_basins(:bacia_belem).id
      }
    }
    assert_redirected_to admin_root_path
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_response :success
  end

  test "show contains turbo frame for side sheet extraction" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail"
  end

  test "show displays station name" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "h2", text: /Estação Belém/
    end
  end

  test "show renders precipitation chart" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-precipitation']"
    end
  end

  test "show renders river level chart" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-river_level']"
    end
  end

  test "show renders temperature chart" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-temperature']"
    end
  end

  test "show lists sensors section" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "turbo-frame#sensor_detail" do
      assert_select "span", text: "Pluviômetro"
      assert_select "span", text: "Fluviômetro"
      assert_select "span", text: "Estação Meteorológica"
    end
  end
end
