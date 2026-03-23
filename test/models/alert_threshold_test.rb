require "test_helper"

class AlertThresholdTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    threshold = AlertThreshold.new(
      parameter: "precipitation",
      threshold_type: "accumulated_1h",
      severity: 2,
      value: 30.0,
      unit: "mm",
      comparison: "gte"
    )
    assert threshold.valid?
  end

  test "invalid without parameter" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.parameter = nil
    assert_not threshold.valid?
  end

  test "invalid without threshold_type" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.threshold_type = nil
    assert_not threshold.valid?
  end

  test "invalid without severity" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.severity = nil
    assert_not threshold.valid?
  end

  test "invalid without value" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.value = nil
    assert_not threshold.valid?
  end

  test "invalid without unit" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.unit = nil
    assert_not threshold.valid?
  end

  test "invalid without comparison" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.comparison = nil
    assert_not threshold.valid?
  end

  test "severity must be between 1 and 4" do
    threshold = alert_thresholds(:precipitation_high)

    threshold.severity = 0
    assert_not threshold.valid?

    threshold.severity = 5
    assert_not threshold.valid?

    threshold.severity = 1
    assert threshold.valid?
  end

  test "comparison must be gt, gte, lt, or lte" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.comparison = "invalid"
    assert_not threshold.valid?
  end

  # ── Scopes ──

  test "active scope returns only active thresholds" do
    active = AlertThreshold.active
    assert_includes active, alert_thresholds(:precipitation_high)
    assert_includes active, alert_thresholds(:river_level_alert)
  end

  test "global scope returns thresholds without risk_zone or river" do
    global = AlertThreshold.global
    assert_not_includes global, alert_thresholds(:precipitation_high)
    assert_not_includes global, alert_thresholds(:river_level_alert)
  end

  # ── Associations ──

  test "belongs to risk zone optionally" do
    assert_equal risk_zones(:zona_centro), alert_thresholds(:precipitation_high).risk_zone
    assert_nil alert_thresholds(:river_level_alert).risk_zone
  end

  test "belongs to river optionally" do
    assert_equal rivers(:belem), alert_thresholds(:river_level_alert).river
    assert_nil alert_thresholds(:precipitation_high).river
  end
end
