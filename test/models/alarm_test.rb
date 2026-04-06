require "test_helper"

class AlarmTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid metric alarm with all required fields" do
    alarm = Alarm.new(
      name: "Test Alarm",
      alarm_type: "metric",
      severity: 2,
      metric_name: "precipitation_1h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      comparison_operator: "GreaterThanOrEqualToThreshold",
      threshold_value: 40.0,
      unit: "mm"
    )
    assert alarm.valid?
  end

  test "valid composite alarm" do
    alarm = Alarm.new(
      name: "Composite Test",
      alarm_type: "composite",
      severity: 4,
      composite_rule: "ALARM(precip_3h_belem) AND ALARM(river_level_belem)"
    )
    assert alarm.valid?
  end

  test "valid anomaly detection alarm" do
    alarm = Alarm.new(
      name: "Anomaly Test",
      alarm_type: "anomaly_detection",
      severity: 2,
      metric_name: "precipitation_1h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      anomaly_band_width: 2.0,
      anomaly_baseline: anomaly_baselines(:precipitation_belem)
    )
    assert alarm.valid?
  end

  test "invalid without name" do
    alarm = alarms(:precip_3h_belem)
    alarm.name = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:name], "can't be blank"
  end

  test "invalid without alarm_type" do
    alarm = alarms(:precip_3h_belem)
    alarm.alarm_type = nil
    assert_not alarm.valid?
  end

  test "invalid with unknown alarm_type" do
    alarm = alarms(:precip_3h_belem)
    alarm.alarm_type = "unknown"
    assert_not alarm.valid?
    assert_includes alarm.errors[:alarm_type], "is not included in the list"
  end

  test "invalid without severity" do
    alarm = alarms(:precip_3h_belem)
    alarm.severity = nil
    assert_not alarm.valid?
  end

  test "severity must be between 1 and 4" do
    alarm = alarms(:precip_3h_belem)

    alarm.severity = 0
    assert_not alarm.valid?

    alarm.severity = 5
    assert_not alarm.valid?

    alarm.severity = 1
    assert alarm.valid?

    alarm.severity = 4
    assert alarm.valid?
  end

  test "invalid with unknown state" do
    alarm = alarms(:precip_3h_belem)
    alarm.state = "invalid"
    assert_not alarm.valid?
    assert_includes alarm.errors[:state], "is not included in the list"
  end

  test "state defaults to insufficient_data" do
    alarm = Alarm.new
    assert_equal "insufficient_data", alarm.state
  end

  # ── Metric alarm validations ──

  test "metric alarm requires metric_name" do
    alarm = alarms(:precip_3h_belem)
    alarm.metric_name = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:metric_name], "can't be blank"
  end

  test "metric alarm requires statistic" do
    alarm = alarms(:precip_3h_belem)
    alarm.statistic = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:statistic], "can't be blank"
  end

  test "metric alarm requires period_seconds" do
    alarm = alarms(:precip_3h_belem)
    alarm.period_seconds = nil
    assert_not alarm.valid?
  end

  test "metric alarm requires evaluation_periods" do
    alarm = alarms(:precip_3h_belem)
    alarm.evaluation_periods = nil
    assert_not alarm.valid?
  end

  test "metric alarm requires datapoints_to_alarm" do
    alarm = alarms(:precip_3h_belem)
    alarm.datapoints_to_alarm = nil
    assert_not alarm.valid?
  end

  test "metric alarm requires comparison_operator" do
    alarm = alarms(:precip_3h_belem)
    alarm.comparison_operator = nil
    assert_not alarm.valid?
  end

  test "metric alarm requires threshold_value" do
    alarm = alarms(:precip_3h_belem)
    alarm.threshold_value = nil
    assert_not alarm.valid?
  end

  test "metric alarm invalid with unknown comparison_operator" do
    alarm = alarms(:precip_3h_belem)
    alarm.comparison_operator = "EqualTo"
    assert_not alarm.valid?
  end

  test "metric alarm invalid with unknown statistic" do
    alarm = alarms(:precip_3h_belem)
    alarm.statistic = "Median"
    assert_not alarm.valid?
  end

  test "metric alarm invalid with unknown missing_data_treatment" do
    alarm = alarms(:precip_3h_belem)
    alarm.missing_data_treatment = "unknown"
    assert_not alarm.valid?
  end

  test "datapoints_to_alarm cannot exceed evaluation_periods" do
    alarm = alarms(:precip_3h_belem)
    alarm.datapoints_to_alarm = 5
    alarm.evaluation_periods = 3
    assert_not alarm.valid?
    assert_includes alarm.errors[:datapoints_to_alarm], "must be less than or equal to evaluation_periods"
  end

  test "period_seconds must be positive" do
    alarm = alarms(:precip_3h_belem)
    alarm.period_seconds = 0
    assert_not alarm.valid?
  end

  # ── Composite alarm validations ──

  test "composite alarm requires composite_rule" do
    alarm = alarms(:composite_flood_belem)
    alarm.composite_rule = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:composite_rule], "can't be blank"
  end

  test "composite alarm does not require metric fields" do
    alarm = Alarm.new(
      name: "Composite",
      alarm_type: "composite",
      severity: 3,
      composite_rule: "ALARM(test)"
    )
    assert alarm.valid?
  end

  # ── Anomaly detection validations ──

  test "anomaly alarm requires anomaly_band_width" do
    alarm = alarms(:anomaly_precip_belem)
    alarm.anomaly_band_width = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:anomaly_band_width], "can't be blank"
  end

  test "anomaly_band_width must be positive" do
    alarm = alarms(:anomaly_precip_belem)
    alarm.anomaly_band_width = 0
    assert_not alarm.valid?
  end

  # ── Scopes ──

  test "enabled scope returns only enabled alarms" do
    enabled = Alarm.enabled
    assert_includes enabled, alarms(:precip_3h_belem)
    assert_includes enabled, alarms(:river_level_belem)
    assert_not_includes enabled, alarms(:disabled_alarm)
  end

  test "metric_alarms scope returns only metric type" do
    metrics = Alarm.metric_alarms
    assert_includes metrics, alarms(:precip_3h_belem)
    assert_includes metrics, alarms(:river_level_belem)
    assert_not_includes metrics, alarms(:composite_flood_belem)
    assert_not_includes metrics, alarms(:anomaly_precip_belem)
  end

  test "anomaly_alarms scope returns only anomaly_detection type" do
    anomalies = Alarm.anomaly_alarms
    assert_includes anomalies, alarms(:anomaly_precip_belem)
    assert_not_includes anomalies, alarms(:precip_3h_belem)
  end

  test "composite_alarms scope returns only composite type" do
    composites = Alarm.composite_alarms
    assert_includes composites, alarms(:composite_flood_belem)
    assert_not_includes composites, alarms(:precip_3h_belem)
  end

  test "in_alarm scope returns alarms in alarm state" do
    in_alarm = Alarm.in_alarm
    assert_includes in_alarm, alarms(:river_level_belem)
    assert_not_includes in_alarm, alarms(:precip_3h_belem)
  end

  test "by_state scope filters by state" do
    ok_alarms = Alarm.by_state("ok")
    assert_includes ok_alarms, alarms(:precip_3h_belem)
    assert_not_includes ok_alarms, alarms(:river_level_belem)
  end

  # ── Associations ──

  test "belongs to river basin optionally" do
    assert_equal river_basins(:bacia_belem), alarms(:precip_3h_belem).river_basin
    assert_nil alarms(:disabled_alarm).river_basin
  end

  test "belongs to river optionally" do
    assert_equal rivers(:belem), alarms(:river_level_belem).river
    assert_nil alarms(:precip_3h_belem).river
  end

  test "belongs to anomaly_baseline optionally" do
    assert_equal anomaly_baselines(:precipitation_belem), alarms(:anomaly_precip_belem).anomaly_baseline
    assert_nil alarms(:precip_3h_belem).anomaly_baseline
  end

  test "has many alarm_actions" do
    actions = alarms(:precip_3h_belem).alarm_actions
    assert_includes actions, alarm_actions(:precip_alarm_websocket)
    assert_includes actions, alarm_actions(:precip_ok_websocket)
  end

  test "has many alarm_state_histories" do
    histories = alarms(:river_level_belem).alarm_state_histories
    assert_includes histories, alarm_state_histories(:river_to_alarm)
  end


  test "composite alarm has many child_alarms through composite_alarm_children" do
    composite = alarms(:composite_flood_belem)
    assert_includes composite.child_alarms, alarms(:precip_3h_belem)
    assert_includes composite.child_alarms, alarms(:river_level_belem)
  end

  test "destroying alarm destroys dependent alarm_actions" do
    alarm = alarms(:precip_3h_belem)
    action_ids = alarm.alarm_actions.pluck(:id)
    assert action_ids.any?

    alarm.destroy
    assert_empty AlarmAction.where(id: action_ids)
  end

  test "destroying alarm destroys dependent alarm_state_histories" do
    alarm = alarms(:river_level_belem)
    history_ids = alarm.alarm_state_histories.pluck(:id)
    assert history_ids.any?

    alarm.destroy
    assert_empty AlarmStateHistory.where(id: history_ids)
  end

  test "destroying composite alarm destroys composite_alarm_children" do
    composite = alarms(:composite_flood_belem)
    child_link_ids = composite.composite_alarm_children.pluck(:id)
    assert child_link_ids.any?

    composite.destroy
    assert_empty CompositeAlarmChild.where(id: child_link_ids)
  end

  # ── State Machine: transition_to! ──

  test "transition_to! changes state" do
    alarm = alarms(:precip_3h_belem)
    assert_equal "ok", alarm.state

    alarm.transition_to!("alarm", reason: "2 of 3 breached", datapoints: [1, 2, 3])

    assert_equal "alarm", alarm.state
    assert_not_nil alarm.state_changed_at
    assert_equal "2 of 3 breached", alarm.state_reason
  end

  test "transition_to! creates alarm_state_history record" do
    alarm = alarms(:precip_3h_belem)

    assert_difference "AlarmStateHistory.count", 1 do
      alarm.transition_to!("alarm", reason: "threshold breached", datapoints: [42.0])
    end

    history = alarm.alarm_state_histories.order(created_at: :desc).first
    assert_equal "ok", history.previous_state
    assert_equal "alarm", history.new_state
    assert_equal "threshold breached", history.reason
    assert_equal [42.0], history.datapoints
    assert_not_nil history.evaluated_at
  end

  test "transition_to! is a no-op when state is unchanged" do
    alarm = alarms(:precip_3h_belem)
    assert_equal "ok", alarm.state

    assert_no_difference "AlarmStateHistory.count" do
      alarm.transition_to!("ok", reason: "still ok")
    end
  end

  test "transition_to! records multiple transitions" do
    alarm = alarms(:precip_3h_belem)

    alarm.transition_to!("alarm", reason: "breached")
    alarm.transition_to!("ok", reason: "recovered")

    histories = alarm.alarm_state_histories.order(:created_at)
    assert_equal 3, histories.count  # 1 existing fixture + 2 new (fixture is for precip alarm_to_ok)

    latest = histories.last
    assert_equal "alarm", latest.previous_state
    assert_equal "ok", latest.new_state
  end

  # ── Helper methods ──

  test "ok? returns true when state is ok" do
    assert alarms(:precip_3h_belem).ok?
  end

  test "alarm? returns true when state is alarm" do
    assert alarms(:river_level_belem).alarm?
  end

  test "insufficient_data? returns true when state is insufficient_data" do
    assert alarms(:anomaly_precip_belem).insufficient_data?
  end

  test "metric? returns true for metric type" do
    assert alarms(:precip_3h_belem).metric?
  end

  test "composite? returns true for composite type" do
    assert alarms(:composite_flood_belem).composite?
  end

  test "anomaly_detection? returns true for anomaly_detection type" do
    assert alarms(:anomaly_precip_belem).anomaly_detection?
  end
end
