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
    # A non-firing ("ok") alarm makes the basin monitored → Vigilância. current_severity: 0
    # mirrors the invariant transition_to! maintains for "ok" alarms. Saved without validation
    # (like the fixtures) to skip the metric threshold-band requirement.
    calm.alarms.build(name: "Monitor de Chuva", alarm_type: "metric", state: "ok", current_severity: 0,
      enabled: true, metric_name: "precipitation", statistic: "Sum", period_seconds: 3600,
      evaluation_periods: 3, datapoints_to_alarm: 2).save!(validate: false)

    normal = RiverBasin.by_risk_level("normal")
    assert_includes normal, calm                             # monitored + not firing → Vigilância
    assert_not_includes normal, river_basins(:bacia_belem)   # firing at severity 3
    # bacia_barigui has no alarms → "Não monitorada", which is NOT Vigilância.
    assert_not_includes normal, river_basins(:bacia_barigui)
  end

  test "by_risk_level('normal') excludes a basin monitored only by an insufficient_data alarm" do
    # "insufficient_data" means we don't know the risk, not that it's confirmed calm —
    # it must not show up under any risk-level filter, including Vigilância.
    unknown = RiverBasin.create!(name: "Bacia Sem Dados")
    unknown.alarms.build(name: "Sensor Instável", alarm_type: "metric", state: "insufficient_data",
      enabled: true, metric_name: "precipitation", statistic: "Sum", period_seconds: 3600,
      evaluation_periods: 3, datapoints_to_alarm: 2).save!(validate: false)

    assert_not_includes RiverBasin.by_risk_level("normal"), unknown
  end

  test "alarm_severity reads the basin's max evaluated severity" do
    assert_equal 3, river_basins(:bacia_belem).alarm_severity   # flood_alert_belem fires at 3
    assert_equal 0, river_basins(:bacia_barigui).alarm_severity # unmonitored → falls back to 0
  end

  test "ordered_by_alarm_severity sorts firing basins above calm/unmonitored ones" do
    ordered = RiverBasin.ordered_by_alarm_severity.to_a
    assert_equal river_basins(:bacia_belem), ordered.first
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
