require "test_helper"

class AlarmEvaluationEngineTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
    @river = rivers(:belem)
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
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 1.0,  # readings: 1.2 (5min) and 1.1 (35min) in separate 20min periods
      period_seconds: 1200,  # 20 min periods so readings fall in different periods
      evaluation_periods: 3,
      datapoints_to_alarm: 2,  # 2 of 3 must breach
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
  end

  test "alarm stays ok when fewer than N periods breach" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 1.15,  # only 1.2 breaches; 1.1 and 0.9 don't
      period_seconds: 2400,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,  # need 2, only 1 breaches
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
  end

  # ── Missing data treatment ──

  test "missing data treatment 'breaching' counts missing periods as breaching" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 100.0,  # nothing breaches
      period_seconds: 60,  # 1 min periods — many will be empty
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "breaching",
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    # Empty periods counted as breaching → alarm
    assert_equal "alarm", alarm.reload.state
  end

  test "missing data treatment 'notBreaching' counts missing periods as ok" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 100.0,  # nothing breaches
      period_seconds: 60,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "notBreaching",
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "ok", alarm.reload.state
  end

  test "all periods missing with treatment 'missing' transitions to insufficient_data" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 1.0,
      period_seconds: 60,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "missing",
      river: rivers(:belem)
    )
    # Use a time window with no readings
    travel_to 1.week.from_now do
      AlarmEvaluationEngine.evaluate_alarm(alarm)
    end

    assert_equal "insufficient_data", alarm.reload.state
  end

  test "missing data treatment 'ignore' skips missing periods" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      threshold_value: 0.5,  # all readings breach (1.2, 1.1, 0.9)
      period_seconds: 7200,  # 2h periods
      evaluation_periods: 3,
      datapoints_to_alarm: 1,
      missing_data_treatment: "ignore",
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
  end

  # ── LessThan comparison ──

  test "LessThanThreshold triggers when value is below threshold" do
    alarm = create_metric_alarm(
      state: "ok",
      metric_name: "river_level",
      statistic: "Maximum",
      comparison_operator: "LessThanThreshold",
      threshold_value: 2.0,  # 1.2 < 2.0 → breach
      evaluation_periods: 1,
      datapoints_to_alarm: 1,
      river: @river
    )

    AlarmEvaluationEngine.evaluate_alarm(alarm)

    assert_equal "alarm", alarm.reload.state
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

  def create_metric_alarm(overrides = {})
    defaults = {
      name: "Test Alarm #{SecureRandom.hex(4)}",
      alarm_type: "metric",
      severity: 2,
      river_basin: @basin,
      statistic: "Sum",
      period_seconds: 3600,
      comparison_operator: "GreaterThanOrEqualToThreshold",
      unit: "mm",
      missing_data_treatment: "missing"
    }
    Alarm.create!(defaults.merge(overrides))
  end
end
