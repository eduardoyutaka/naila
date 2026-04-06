require "test_helper"

class AlarmThresholdTest < ActiveSupport::TestCase
  def valid_threshold(overrides = {})
    AlarmThreshold.new({
      alarm: alarms(:precip_3h_belem),
      severity: 1,
      comparison_operator: "GreaterThanOrEqualToThreshold",
      threshold_value: 20.0,
      unit: "mm"
    }.merge(overrides))
  end

  # ── Validations ──

  test "valid with all required fields" do
    assert valid_threshold.valid?
  end

  test "valid without unit" do
    assert valid_threshold(unit: nil).valid?
  end

  test "invalid without severity" do
    t = valid_threshold(severity: nil)
    assert_not t.valid?
    assert_includes t.errors[:severity], "can't be blank"
  end

  test "invalid with severity below 1" do
    t = valid_threshold(severity: 0)
    assert_not t.valid?
    assert t.errors[:severity].any?
  end

  test "invalid with severity above 4" do
    t = valid_threshold(severity: 5)
    assert_not t.valid?
    assert t.errors[:severity].any?
  end

  test "invalid without comparison_operator" do
    t = valid_threshold(comparison_operator: nil)
    assert_not t.valid?
    assert_includes t.errors[:comparison_operator], "can't be blank"
  end

  test "invalid with unknown comparison_operator" do
    t = valid_threshold(comparison_operator: "NotAValidOperator")
    assert_not t.valid?
    assert t.errors[:comparison_operator].any?
  end

  test "invalid without threshold_value" do
    t = valid_threshold(threshold_value: nil)
    assert_not t.valid?
    assert t.errors[:threshold_value].any?
  end

  test "invalid with non-numeric threshold_value" do
    t = valid_threshold(threshold_value: "not a number")
    assert_not t.valid?
    assert t.errors[:threshold_value].any?
  end

  test "invalid when unit exceeds 20 characters" do
    t = valid_threshold(unit: "a" * 21)
    assert_not t.valid?
    assert t.errors[:unit].any?
  end

  test "invalid when severity is duplicated for the same alarm" do
    existing = alarm_thresholds(:precip_belem_sev2)
    duplicate = valid_threshold(alarm: existing.alarm, severity: existing.severity)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:severity], "já existe para este alarme"
  end

  test "same severity is valid for different alarms" do
    t = valid_threshold(alarm: alarms(:river_level_belem), severity: 2)
    # river_level_belem already has sev 2 via fixture — so this would fail.
    # Use a fresh alarm instead.
    fresh_alarm = Alarm.create!(
      name: "Fresh Alarm",
      alarm_type: "metric",
      severity: 1,
      metric_name: "precipitation_1h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 1,
      datapoints_to_alarm: 1,
      comparison_operator: "GreaterThanThreshold",
      threshold_value: 10.0
    )
    t2 = valid_threshold(alarm: fresh_alarm, severity: 2)
    assert t2.valid?
  end

  # ── Associations ──

  test "belongs to alarm" do
    threshold = alarm_thresholds(:precip_belem_sev2)
    assert_equal alarms(:precip_3h_belem), threshold.alarm
  end
end
