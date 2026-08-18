require "test_helper"

class MetricDataCollectorTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
  end

  # ── precipitation ──

  test "collects precipitation sum for basin over a 1h window" do
    # Fixture readings in last 1h: 12.5 (10min ago) + 8.2 (40min ago) = 20.7
    result = MetricDataCollector.collect(
      metric_name: "precipitation",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current
    )
    assert_in_delta 20.7, result, 0.1
  end

  test "precipitation returns 0 when no readings in window" do
    result = MetricDataCollector.collect(
      metric_name: "precipitation",
      river_basin: @basin,
      period_start: 2.days.ago,
      period_end: 1.day.ago
    )
    assert_in_delta 0.0, result, 0.01
  end

  test "collects precipitation sum for basin over a 3h window" do
    # Fixture readings within 3h window: 12.5 + 8.2 + 3.1 = 23.8
    # (5.7 at exactly 3h ago may fall outside the range boundary)
    result = MetricDataCollector.collect(
      metric_name: "precipitation",
      river_basin: @basin,
      period_start: 3.hours.ago,
      period_end: Time.current
    )
    assert_in_delta 23.8, result, 0.2
  end

  test "collects precipitation sum for basin over a 24h window" do
    # The window is whatever's passed in — precipitation isn't split by period length.
    # Fixture readings within 24h: 12.5+8.2+3.1+5.7+15.3+2.0 = 46.8
    result = MetricDataCollector.collect(
      metric_name: "precipitation",
      river_basin: @basin,
      period_start: 24.hours.ago,
      period_end: Time.current
    )
    assert_in_delta 46.8, result, 0.2
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
      metric_name: "precipitation",
      river_basin: @basin,
      period_start: 1.hour.ago,
      period_end: Time.current,
      statistic: "Sum"
    )
    assert_in_delta 20.7, result, 0.1
  end

  # ── history_series ──

  test "history_series returns one entry per requested period, oldest first" do
    alarm = alarms(:flood_alert_belem)

    series = MetricDataCollector.history_series(alarm: alarm, periods: 4)

    assert_equal 4, series.length
    assert series.all? { |pt| pt.key?(:period_end) && pt.key?(:value) }
    period_ends = series.map { |pt| pt[:period_end] }
    assert_equal period_ends.sort, period_ends, "expected oldest → newest ordering"
  end

  test "history_series spans periods of the alarm's period_seconds length" do
    alarm = alarms(:flood_alert_belem) # period_seconds: 3600

    series = MetricDataCollector.history_series(alarm: alarm, periods: 3)

    gap = series[-1][:period_end] - series[-2][:period_end]
    assert_in_delta alarm.period_seconds, gap, 1
  end

  test "history_series most recent entry matches a single collect call for the same window" do
    alarm = alarms(:flood_alert_belem)

    series = MetricDataCollector.history_series(alarm: alarm, periods: 3)
    latest = series.last

    direct = MetricDataCollector.collect(
      metric_name: alarm.metric_name,
      river_basin: alarm.river_basin,
      river: alarm.river,
      period_start: latest[:period_end] - alarm.period_seconds.seconds,
      period_end: latest[:period_end],
      statistic: alarm.statistic
    )
    assert_equal direct, latest[:value]
  end

  # ── metric list consistency ──

  test "every supported metric has a display label, so nothing renders as a raw key" do
    MetricDataCollector::SUPPORTED_METRICS.each do |metric_name|
      assert RiskHelper::METRIC_NAME_LABEL.key?(metric_name),
        "#{metric_name} is in SUPPORTED_METRICS but missing from RiskHelper::METRIC_NAME_LABEL"
    end
  end
end
