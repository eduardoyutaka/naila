require "test_helper"

class RiverBasinTest < ActiveSupport::TestCase
  # ── Filter Scopes ──

  test "by_risk_level scope filters basins by their max alarm severity" do
    # Fixture: flood_alert_belem fires at severity 3 (high_alert) on bacia_belem.
    high_alert = RiverBasin.by_risk_level("high_alert")
    assert_includes high_alert, river_basins(:bacia_belem)
    assert_not_includes high_alert, river_basins(:bacia_barigui)
  end

  test "by_risk_level('normal') means Vigilância — monitored basins with no firing alarm, not unmonitored ones" do
    # Vigilância = a basin that HAS an alarm configured but nothing currently firing.
    calm = RiverBasin.create!(name: "Bacia Calma")
    # A non-firing ("ok") alarm makes the basin monitored → Vigilância. Saved without
    # validation (like the fixtures) to skip the metric threshold-band requirement.
    calm.alarms.build(name: "Monitor de Chuva", alarm_type: "metric", state: "ok", enabled: true,
      metric_name: "precipitation_3h", statistic: "Sum", period_seconds: 3600,
      evaluation_periods: 3, datapoints_to_alarm: 2).save!(validate: false)

    normal = RiverBasin.by_risk_level("normal")
    assert_includes normal, calm                             # monitored + not firing → Vigilância
    assert_not_includes normal, river_basins(:bacia_belem)   # firing at severity 3
    # bacia_barigui has no alarms → "Não monitorada", which is NOT Vigilância.
    assert_not_includes normal, river_basins(:bacia_barigui)
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
