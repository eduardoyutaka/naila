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

  test "index shows summary cards with connected and disconnected counts" do
    connected_count    = MonitoringStation.connection_status_connected.count
    disconnected_count = MonitoringStation.connection_status_disconnected.count
    assert_operator disconnected_count, :>=, 1

    get admin_monitoring_stations_path
    assert_select "[data-testid='summary-total-count']"
    assert_select "[data-testid='summary-connected-count']",    text: connected_count.to_s
    assert_select "[data-testid='summary-disconnected-count']", text: disconnected_count.to_s
  end

  test "index shows sensor type badges" do
    get admin_monitoring_stations_path
    assert_select "span", text: "Pluviômetro"
  end

  test "index shows status indicators" do
    get admin_monitoring_stations_path
    assert_select "span", text: "Ativo"
    assert_select "span", text: "Manutenção"
  end

  test "index shows connectivity indicators" do
    get admin_monitoring_stations_path
    # Regexp match, not exact — a "connected" station may show the plain or the stale
    # ("Conectado (sem leitura recente)") variant depending on its last reading.
    assert_select "span", text: /Conectado/
    assert_select "span", text: /Desconectado/
  end

  test "index flags a connected station with no recent reading as stale" do
    # cemaden_centro: connection_status connected, but no sensor_readings fixture at all.
    get admin_monitoring_stations_path
    assert_select "span", text: "Conectado (sem leitura recente)"
  end

  test "index shows 'Sem dados' for a station that has never been polled" do
    MonitoringStation.create!(
      external_id: "NUNCA-POLLED", name: "Estação Nunca Consultada",
      data_source: "CEMADEN", river_basin: river_basins(:bacia_belem)
    )

    get admin_monitoring_stations_path
    assert_select "span", text: "Sem dados"
  end

  test "index shows empty state when no stations exist" do
    MonitoringStation.destroy_all
    get admin_monitoring_stations_path
    assert_select "div", text: /Nenhuma estação encontrada/
  end

  # ── Filters ──

  test "index filters by status" do
    get admin_monitoring_stations_path(q: { status: "maintenance" })
    assert_response :success
    assert_select "td", text: /Estação Barigui/
    assert_select "td", text: /Estação Belém/, count: 0
  end

  test "index filters by connection_status" do
    get admin_monitoring_stations_path(q: { connection_status: "disconnected" })
    assert_response :success
    assert_select "td", text: /Estação Belém/
    assert_select "td", text: /Estação Barigui/
    assert_select "td", text: /Estação CEMADEN Centro/, count: 0
  end

  test "index filters by search" do
    get admin_monitoring_stations_path(q: { search: "Barigui" })
    assert_response :success
    assert_select "td", text: /Estação Barigui/
    assert_select "td", text: /Estação Belém/, count: 0
  end

  test "index shows clear filters link when no results" do
    get admin_monitoring_stations_path(q: { search: "nonexistent" })
    assert_response :success
    assert_select "a", text: /Limpar filtros/
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

  # ── Show (side-sheet via Turbo Frame) ──

  test "show contains turbo frame for side sheet extraction" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem)), headers: { "Turbo-Frame" => "sensor_detail" }
    assert_select "turbo-frame#sensor_detail"
  end

  test "show displays station name in side sheet" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem)), headers: { "Turbo-Frame" => "sensor_detail" }
    assert_select "turbo-frame#sensor_detail" do
      assert_select "h2", text: /Estação Belém/
    end
  end

  test "show renders precipitation chart in side sheet" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem)), headers: { "Turbo-Frame" => "sensor_detail" }
    assert_select "turbo-frame#sensor_detail" do
      assert_select "[data-testid='reading-chart-precipitation']"
    end
  end

  test "show lists sensors section in side sheet" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem)), headers: { "Turbo-Frame" => "sensor_detail" }
    assert_select "turbo-frame#sensor_detail" do
      assert_select "span", text: "Pluviômetro"
    end
  end

  # ── Show (full-page layout) ──

  test "show full page displays station name in h1" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "h1", text: /Estação Belém/
  end

  test "show full page contains back link" do
    get admin_monitoring_station_path(monitoring_stations(:estacao_belem))
    assert_select "a[href='#{admin_monitoring_stations_path}']"
  end

  test "show full page flags a connected station with no recent reading as stale" do
    get admin_monitoring_station_path(monitoring_stations(:cemaden_centro))
    assert_select "span", text: "Conectado (sem leitura recente)"
  end
end
