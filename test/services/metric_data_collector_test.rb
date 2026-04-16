require "test_helper"

class MetricDataCollectorTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
  end

  # ── precipitation_1h ──

  test "collects precipitation_1h sum for basin" do
    # Fixture readings in last 1h: 12.5 (10min ago) + 8.2 (40min ago) = 20.7
    result = MetricDataCollector.collect(
      metric_name: "precipitation_1h",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current
    )
    assert_in_delta 20.7, result, 0.1
  end

  test "precipitation_1h returns 0 when no readings in window" do
    result = MetricDataCollector.collect(
      metric_name: "precipitation_1h",
      river_basin: @basin,
      period_start: 2.days.ago,
      period_end: 1.day.ago
    )
    assert_in_delta 0.0, result, 0.01
  end

  # ── precipitation_3h ──

  test "collects precipitation_3h sum for basin" do
    # Fixture readings within 3h window: 12.5 + 8.2 + 3.1 = 23.8
    # (5.7 at exactly 3h ago may fall outside the range boundary)
    result = MetricDataCollector.collect(
      metric_name: "precipitation_3h",
      river_basin: @basin,
      period_start: 3.hours.ago,
      period_end: Time.current
    )
    assert_in_delta 23.8, result, 0.2
  end

  # ── risk_score ──

  test "collects latest risk_score for basin" do
    RiskAssessment.create!(
      river_basin: @basin,
      assessed_at: 10.minutes.ago,
      risk_level: 2,
      risk_score: 0.55
    )

    result = MetricDataCollector.collect(
      metric_name: "risk_score",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current
    )
    assert_in_delta 0.55, result, 0.01
  end

  test "risk_score returns nil when no assessments in window" do
    result = MetricDataCollector.collect(
      metric_name: "risk_score",
      river_basin: @basin,
      period_start: 2.days.ago,
      period_end: 1.day.ago
    )
    assert_nil result
  end

  # ── unknown metric ──

  test "returns nil for unknown metric_name" do
    result = MetricDataCollector.collect(
      metric_name: "unknown_metric",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current
    )
    assert_nil result
  end

  # ── applying statistic ──

  test "applies Sum statistic to precipitation readings" do
    result = MetricDataCollector.collect(
      metric_name: "precipitation_1h",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current,
      statistic: "Sum"
    )
    assert_in_delta 20.7, result, 0.1
  end

end
