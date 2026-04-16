require "test_helper"

class AlarmEvaluationEngineTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
  end

  # ── Metric alarm: basic state transitions ──

  test "transitions metric alarm from ok to alarm when threshold breached" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 10.0,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    # Fixture has ~20.7mm in last hour, > 10.0 threshold

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
    assert_equal 1, alarm.alarm_state_histories.count
  end

  test "keeps metric alarm in ok when threshold not breached" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 100.0,  # very high, won't be breached
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
    assert_equal 0, alarm.alarm_state_histories.count
  end

  test "transitions metric alarm from alarm back to ok when threshold no longer breached" do
    alarm = create_metric_alarm(
      state: "alarm",
      state_changed_at: 1.hour.ago,
      metric_name: "precipitation_1h",
      threshold_value: 100.0,  # no longer breached
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
  end

  # ── N-out-of-M evaluation ──

  test "alarm triggers when N of M periods breach threshold" do
    basin = build_isolated_basin_with_pluviometer(readings: [[1.2, 5.minutes.ago], [1.1, 35.minutes.ago], [0.9, 2.hours.ago]])
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      statistic: "Maximum",
      threshold_value: 1.0,  # readings: 1.2 (5min) and 1.1 (35min) in separate 20min periods
      period_seconds: 1200,  # 20 min periods so readings fall in different periods
      evaluation_periods: 3,
      datapoints_to_alarm: 2,  # 2 of 3 must breach
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
  end

  test "alarm stays ok when fewer than N periods breach" do
    basin = build_isolated_basin_with_pluviometer(readings: [[1.2, 5.minutes.ago], [1.1, 35.minutes.ago], [0.9, 2.hours.ago]])
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      statistic: "Maximum",
      threshold_value: 1.15,  # only 1.2 breaches; 1.1 and 0.9 don't
      period_seconds: 2400,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,  # need 2, only 1 breaches
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
  end

  # ── Missing data treatment ──

  # Missing-data tests use the risk_score metric because MetricDataCollector
  # returns nil for it when no assessments exist in a period — the signal the
  # engine needs to treat a period as missing. Precipitation always returns 0.0
  # for empty windows, which would never look "missing" to the engine.
  test "missing data treatment 'breaching' counts missing periods as breaching" do
    basin = RiverBasin.create!(name: "Missing-breaching #{SecureRandom.hex(4)}", active: true, current_risk_level: 0)
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "risk_score",
      statistic: "Maximum",
      threshold_value: 100.0,  # nothing breaches
      period_seconds: 60,  # 1 min periods — all empty (no assessments)
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "breaching",
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    # Empty periods counted as breaching → alarm
    assert_equal "alarm", alarm.reload.state
  end

  test "missing data treatment 'notBreaching' counts missing periods as ok" do
    basin = RiverBasin.create!(name: "Missing-notbreaching #{SecureRandom.hex(4)}", active: true, current_risk_level: 0)
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "risk_score",
      statistic: "Maximum",
      threshold_value: 100.0,
      period_seconds: 60,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "notBreaching",
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
  end

  test "all periods missing with treatment 'missing' transitions to insufficient_data" do
    basin = RiverBasin.create!(name: "Missing-insufficient #{SecureRandom.hex(4)}", active: true, current_risk_level: 0)
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "risk_score",
      statistic: "Maximum",
      threshold_value: 0.5,
      period_seconds: 60,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "missing",
      river_basin: basin
    )
    # No RiskAssessment records → all periods empty
    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "insufficient_data", alarm.reload.state
  end

  test "missing data treatment 'ignore' skips missing periods" do
    basin = RiverBasin.create!(name: "Missing-ignore #{SecureRandom.hex(4)}", active: true, current_risk_level: 0)
    # One assessment in period 1 (0-2h); periods 2 (2-4h) and 3 (4-6h) empty
    RiskAssessment.create!(
      river_basin: basin,
      assessed_at: 30.minutes.ago,
      risk_level: 2,
      risk_score: 0.55
    )
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "risk_score",
      statistic: "Maximum",
      threshold_value: 0.5,  # 0.55 breaches
      period_seconds: 7200,  # 2h periods
      evaluation_periods: 3,
      datapoints_to_alarm: 1,
      missing_data_treatment: "ignore",
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
  end

  # ── LessThan comparison ──

  test "LessThanThreshold triggers when value is below threshold" do
    basin = build_isolated_basin_with_pluviometer(readings: [[1.2, 5.minutes.ago], [1.1, 35.minutes.ago], [0.9, 2.hours.ago]])
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      statistic: "Maximum",
      comparison_operator: "LessThanThreshold",
      threshold_value: 2.0,  # 1.2 < 2.0 → breach
      evaluation_periods: 1,
      datapoints_to_alarm: 1,
      river_basin: basin
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
  end

  # ── Multi-threshold band evaluation ──

  test "sets current_severity to the highest breached threshold band" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 10.0,  # sev 1 band: >= 10mm (readings are ~20mm)
      severity: 1,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    # Add a sev 2 band at 25mm (won't be breached by ~20mm readings)
    alarm.alarm_thresholds.create!(severity: 2, comparison_operator: "GreaterThanOrEqualToThreshold",
                                   threshold_value: 25.0, unit: "mm")

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
    assert_equal 1, alarm.current_severity
  end

  test "escalates to higher severity when higher band is also breached" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 5.0,  # sev 1 band: >= 5mm
      severity: 1,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    # sev 2 band at 15mm — also breached by ~20mm readings
    alarm.alarm_thresholds.create!(severity: 2, comparison_operator: "GreaterThanOrEqualToThreshold",
                                   threshold_value: 15.0, unit: "mm")

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
    assert_equal 2, alarm.current_severity
  end

  test "transitions from alarm to ok clears current_severity" do
    alarm = create_metric_alarm(
      state: "alarm",
      current_severity: 2,
      metric_name: "precipitation_1h",
      threshold_value: 100.0,  # won't be breached
      severity: 2,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
    assert_nil alarm.current_severity
  end

  test "severity downgrade records history without changing state_changed_at" do
    alarm = create_metric_alarm(
      state: "alarm",
      current_severity: 2,
      metric_name: "precipitation_1h",
      threshold_value: 5.0,   # sev 1: >= 5mm (readings ~20mm breaches this)
      severity: 1,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    # sev 2 band at 25mm — readings ~20mm will NOT breach this
    alarm.alarm_thresholds.create!(severity: 2, comparison_operator: "GreaterThanOrEqualToThreshold",
                                   threshold_value: 25.0, unit: "mm")
    original_state_changed_at = alarm.state_changed_at

    assert_difference "AlarmStateHistory.count", 1 do
      AlarmEvaluationEngine.evaluate_alarm(alarm)
    end

    alarm.reload
    assert_equal "alarm", alarm.state
    assert_equal 1, alarm.current_severity
    assert_equal original_state_changed_at.to_i, alarm.state_changed_at.to_i
  end

  # ── evaluate_all ──

  test "evaluate_all evaluates all enabled alarms" do
    # Fixtures have enabled alarms in various states
    assert_nothing_raised do
      AlarmEvaluationEngine.evaluate_all
    end
  end

  test "evaluate_all skips disabled alarms" do
    disabled = alarms(:disabled_alarm)
    original_state = disabled.state

    AlarmEvaluationEngine.evaluate_all

    assert_equal original_state, disabled.reload.state
  end

  # ── Updates last_evaluated_at and last_datapoints ──

  test "updates last_evaluated_at after evaluation" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 100.0,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    assert_nil alarm.last_evaluated_at

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_not_nil alarm.reload.last_evaluated_at
  end

  test "stores last_datapoints for debugging" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "precipitation_1h",
      threshold_value: 100.0,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert alarm.reload.last_datapoints.is_a?(Array)
    assert alarm.last_datapoints.any?
  end

  private

  # Creates a fresh basin + station + pluviometer with the given readings,
  # isolated from fixture-provided pluvios so tests can control precipitation
  # values precisely. Returns the basin for binding to an alarm.
  def build_isolated_basin_with_pluviometer(readings:)
    suffix = SecureRandom.hex(4)
    basin = RiverBasin.create!(name: "Test Basin #{suffix}", active: true, current_risk_level: 0)
    station = MonitoringStation.create!(
      external_id: "TEST-STATION-#{suffix}",
      name: "Test Station #{suffix}",
      data_source: "TEST",
      status: :active,
      river_basin: basin
    )
    sensor = Sensor.create!(
      monitoring_station: station,
      sensor_type: :pluviometer,
      external_id: "TEST-PLUV-#{suffix}",
      unit: "mm",
      reading_type: "precipitation",
      status: :active
    )
    readings.each do |value, recorded_at|
      SensorReading.create!(
        sensor: sensor,
        value: value,
        unit: "mm",
        reading_type: "precipitation",
        recorded_at: recorded_at
      )
    end
    basin
  end

  def create_metric_alarm(overrides = {})
    # Extract threshold band fields — they go on AlarmThreshold, not Alarm
    severity        = overrides.delete(:severity) || 2
    comparison_op   = overrides.delete(:comparison_operator) || "GreaterThanOrEqualToThreshold"
    threshold_value = overrides.delete(:threshold_value)
    unit            = overrides.delete(:unit) || "mm"

    raise ArgumentError, "threshold_value is required for create_metric_alarm" if threshold_value.nil?

    defaults = {
      name: "Test Alarm #{SecureRandom.hex(4)}",
      alarm_type: "metric",
      river_basin: @basin,
      statistic: "Sum",
      period_seconds: 3600,
      missing_data_treatment: "missing"
    }
    alarm = Alarm.new(defaults.merge(overrides))
    alarm.alarm_thresholds.build(
      severity: severity,
      comparison_operator: comparison_op,
      threshold_value: threshold_value,
      unit: unit
    )
    alarm.save!
    alarm
  end
end
