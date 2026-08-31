require "test_helper"

class MonitoringStationTest < ActiveSupport::TestCase
  # ── Filter Scopes ──

  test "by_status scope filters by status" do
    active = MonitoringStation.by_status("active")
    assert_includes active, monitoring_stations(:estacao_belem)
    assert_not_includes active, monitoring_stations(:estacao_barigui)

    maintenance = MonitoringStation.by_status("maintenance")
    assert_includes maintenance, monitoring_stations(:estacao_barigui)
  end

  test "search_by_name scope filters by name with ILIKE" do
    results = MonitoringStation.search_by_name("belém")
    assert_includes results, monitoring_stations(:estacao_belem)
    assert_not_includes results, monitoring_stations(:estacao_barigui)
  end

  test "search_by_name scope returns all when term is blank" do
    assert_equal MonitoringStation.count, MonitoringStation.search_by_name("").count
    assert_equal MonitoringStation.count, MonitoringStation.search_by_name(nil).count
  end

  test "by_connection_status scope filters by connection_status" do
    connected = MonitoringStation.by_connection_status("connected")
    assert_includes connected, monitoring_stations(:cemaden_centro)
    assert_not_includes connected, monitoring_stations(:estacao_belem)

    disconnected = MonitoringStation.by_connection_status("disconnected")
    assert_includes disconnected, monitoring_stations(:estacao_belem)
    assert_not_includes disconnected, monitoring_stations(:cemaden_centro)
  end

  # ── Connectivity ──

  test "connected and disconnected scopes filter by connection_status" do
    connected = MonitoringStation.connected
    assert_includes connected, monitoring_stations(:cemaden_centro)
    assert_not_includes connected, monitoring_stations(:estacao_belem)

    disconnected = MonitoringStation.disconnected
    assert_includes disconnected, monitoring_stations(:estacao_belem)
    assert_not_includes disconnected, monitoring_stations(:cemaden_centro)
  end

  test "record_fetch_success! marks the station connected and stamps last_successful_fetch_at" do
    station = monitoring_stations(:estacao_belem)

    station.record_fetch_success!

    assert station.connection_status_connected?
    assert_not_nil station.last_successful_fetch_at
  end

  test "record_fetch_failure! marks the station disconnected and stamps last_failed_fetch_at" do
    station = monitoring_stations(:cemaden_centro)

    station.record_fetch_failure!

    assert station.connection_status_disconnected?
    assert_not_nil station.last_failed_fetch_at
  end

  test "defaults to unknown connectivity for a station that has never been polled" do
    station = MonitoringStation.new(
      external_id: "TEST-UNPOLLED", name: "Estação Nunca Consultada",
      data_source: "CEMADEN", river_basin: river_basins(:bacia_belem)
    )

    assert station.connection_status_unknown?
  end

  # ── Staleness ──

  test "stale? is true when connected with no readings at all" do
    station = monitoring_stations(:cemaden_centro) # connected, no sensor_readings fixture
    assert station.connection_status_connected?
    assert_nil station.last_reading

    assert station.stale?
  end

  test "stale? is true when connected but the last reading is older than the threshold" do
    station = monitoring_stations(:cemaden_centro)
    sensors(:pluv_cemaden_centro).sensor_readings.create!(
      value: 1.0, unit: "mm", reading_type: "precipitation",
      recorded_at: (MonitoringStation::STALE_THRESHOLD + 1.hour).ago
    )

    assert station.stale?
  end

  test "stale? is false when connected with a recent reading" do
    station = monitoring_stations(:estacao_belem) # has a reading from 10 minutes ago
    station.connection_status = "connected"

    assert_not station.stale?
  end

  test "stale? is false when disconnected or unknown, regardless of reading age" do
    disconnected = monitoring_stations(:estacao_belem) # already disconnected, has readings
    assert disconnected.connection_status_disconnected?
    assert_not disconnected.stale?

    unknown = monitoring_stations(:cemaden_centro)
    unknown.connection_status = "unknown"
    assert_not unknown.stale?
  end

  # ── Configured basins (mirror of RiverBasin#configured_monitoring_stations) ──

  test "configured_for_basins returns basins this station is configured to feed" do
    assert_equal [ river_basins(:bacia_belem) ], monitoring_stations(:estacao_belem).configured_for_basins.to_a
  end

  test "configured_for_basins includes every basin sharing this station, not just its home basin" do
    station = monitoring_stations(:estacao_belem) # home basin: bacia_belem
    river_basins(:bacia_barigui).configured_monitoring_stations << station

    assert_includes station.configured_for_basins, river_basins(:bacia_belem)
    assert_includes station.configured_for_basins, river_basins(:bacia_barigui)
  end

  test "creating a station auto-configures it to feed its own home basin" do
    station = MonitoringStation.create!(
      external_id: "TEST-AUTOCONFIG", name: "Estação Auto-config",
      data_source: "CEMADEN", river_basin: river_basins(:bacia_barigui)
    )

    assert_includes river_basins(:bacia_barigui).configured_monitoring_stations, station
  end
end
