require "test_helper"

class RiverBasinTest < ActiveSupport::TestCase
  # ── Filter Scopes ──

  test "by_risk_level scope filters basins by their max alarm severity" do
    # Fixture: flood_alert_belem fires at severity 3 (high_alert) on bacia_belem.
    high_alert = RiverBasin.by_risk_level("high_alert")
    assert_includes high_alert, river_basins(:bacia_belem)
    assert_not_includes high_alert, river_basins(:bacia_barigui)

    # bacia_barigui has no firing alarms, so it shows up under "normal" only.
    normal = RiverBasin.by_risk_level("normal")
    assert_includes normal, river_basins(:bacia_barigui)
    assert_not_includes normal, river_basins(:bacia_belem)
  end

  test "by_active scope filters by active flag" do
    active = RiverBasin.by_active(true)
    assert_includes active, river_basins(:bacia_belem)
    assert_includes active, river_basins(:bacia_barigui)
  end

  test "search_by_name scope filters by name with ILIKE" do
    results = RiverBasin.search_by_name("belém")
    assert_includes results, river_basins(:bacia_belem)
    assert_not_includes results, river_basins(:bacia_barigui)
  end

  test "search_by_name scope returns all when term is blank" do
    assert_equal RiverBasin.count, RiverBasin.search_by_name("").count
    assert_equal RiverBasin.count, RiverBasin.search_by_name(nil).count
  end
end
