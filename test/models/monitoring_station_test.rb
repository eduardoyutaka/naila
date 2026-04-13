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
end
