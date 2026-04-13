require "test_helper"

class RiverBasinTest < ActiveSupport::TestCase
  # ── Filter Scopes ──

  test "by_risk_level scope filters by risk level" do
    alert = RiverBasin.by_risk_level("alert")
    assert_includes alert, river_basins(:bacia_belem)
    assert_not_includes alert, river_basins(:bacia_barigui)
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
