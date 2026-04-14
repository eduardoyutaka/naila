require "test_helper"

class AlarmTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid metric alarm with all required fields" do
    alarm = Alarm.new(
      name: "Test Alarm",
      alarm_type: "metric",
      metric_name: "precipitation_1h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 3,
      datapoints_to_alarm: 2
    )
    alarm.alarm_thresholds.build(
      severity: 2,
      comparison_operator: "GreaterThanOrEqualToThreshold",
      threshold_value: 40.0,
      unit: "mm"
    )
    assert alarm.valid?
  end

  test "invalid without name" do
    alarm = alarms(:precip_3h_belem)
    alarm.name = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:name], "não pode ficar em branco"
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
    assert_includes alarm.errors[:alarm_type], "não está incluído na lista"
  end

  test "invalid with unknown state" do
    alarm = alarms(:precip_3h_belem)
    alarm.state = "invalid"
    assert_not alarm.valid?
    assert_includes alarm.errors[:state], "não está incluído na lista"
  end

  test "state defaults to insufficient_data" do
    alarm = Alarm.new
    assert_equal "insufficient_data", alarm.state
  end

  test "requires metric_name" do
    alarm = alarms(:precip_3h_belem)
    alarm.metric_name = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:metric_name], "não pode ficar em branco"
  end

  test "requires statistic" do
    alarm = alarms(:precip_3h_belem)
    alarm.statistic = nil
    assert_not alarm.valid?
    assert_includes alarm.errors[:statistic], "não pode ficar em branco"
  end

  test "requires period_seconds" do
    alarm = alarms(:precip_3h_belem)
    alarm.period_seconds = nil
    assert_not alarm.valid?
  end

  test "requires evaluation_periods" do
    alarm = alarms(:precip_3h_belem)
    alarm.evaluation_periods = nil
    assert_not alarm.valid?
  end

  test "requires datapoints_to_alarm" do
    alarm = alarms(:precip_3h_belem)
    alarm.datapoints_to_alarm = nil
    assert_not alarm.valid?
  end

  test "invalid with unknown statistic" do
    alarm = alarms(:precip_3h_belem)
    alarm.statistic = "Median"
    assert_not alarm.valid?
  end

  test "invalid with unknown missing_data_treatment" do
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

  test "requires at least one threshold band" do
    alarm = Alarm.new(
      name: "No Thresholds",
      alarm_type: "metric",
      metric_name: "precipitation_1h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 1,
      datapoints_to_alarm: 1
    )
    assert_not alarm.valid?
    assert alarm.errors[:base].any? { |e| e.include?("faixa de limiar") }
  end

  # ── Scopes ──

  test "enabled scope returns only enabled alarms" do
    enabled = Alarm.enabled
    assert_includes enabled, alarms(:precip_3h_belem)
    assert_includes enabled, alarms(:flood_alert_belem)
    assert_not_includes enabled, alarms(:disabled_alarm)
  end

  test "metric_alarms scope returns only metric type" do
    metrics = Alarm.metric_alarms
    assert_includes metrics, alarms(:precip_3h_belem)
    assert_includes metrics, alarms(:flood_alert_belem)
  end

  test "in_alarm scope returns alarms in alarm state" do
    in_alarm = Alarm.in_alarm
    assert_includes in_alarm, alarms(:flood_alert_belem)
    assert_not_includes in_alarm, alarms(:precip_3h_belem)
  end

  test "by_state scope filters by state" do
    ok_alarms = Alarm.by_state("ok")
    assert_includes ok_alarms, alarms(:precip_3h_belem)
    assert_not_includes ok_alarms, alarms(:flood_alert_belem)
  end

  test "by_enabled scope filters by enabled flag" do
    enabled = Alarm.by_enabled(true)
    assert_includes enabled, alarms(:precip_3h_belem)
    assert_not_includes enabled, alarms(:disabled_alarm)

    disabled = Alarm.by_enabled(false)
    assert_includes disabled, alarms(:disabled_alarm)
    assert_not_includes disabled, alarms(:precip_3h_belem)
  end

  test "search_by_name scope filters by name with ILIKE" do
    results = Alarm.search_by_name("precipitação")
    assert_includes results, alarms(:precip_3h_belem)
    assert_not_includes results, alarms(:flood_alert_belem)
  end

  test "search_by_name scope returns all when term is blank" do
    assert_equal Alarm.count, Alarm.search_by_name("").count
    assert_equal Alarm.count, Alarm.search_by_name(nil).count
  end

  # ── Associations ──

  test "belongs to river basin optionally" do
    assert_equal river_basins(:bacia_belem), alarms(:precip_3h_belem).river_basin
    assert_nil alarms(:disabled_alarm).river_basin
  end

  test "belongs to river optionally" do
    assert_equal rivers(:belem), alarms(:flood_alert_belem).river
    assert_nil alarms(:precip_3h_belem).river
  end

  test "has many alarm_thresholds" do
    thresholds = alarms(:flood_alert_belem).alarm_thresholds
    assert_includes thresholds, alarm_thresholds(:flood_belem_sev2)
    assert_includes thresholds, alarm_thresholds(:flood_belem_sev3)
  end

  test "destroying alarm destroys dependent alarm_thresholds" do
    alarm = alarms(:precip_3h_belem)
    threshold_ids = alarm.alarm_thresholds.pluck(:id)
    assert threshold_ids.any?

    alarm.destroy
    assert_empty AlarmThreshold.where(id: threshold_ids)
  end

  test "has many alarm_actions" do
    actions = alarms(:precip_3h_belem).alarm_actions
    assert_includes actions, alarm_actions(:precip_alarm_websocket)
    assert_includes actions, alarm_actions(:precip_ok_websocket)
  end

  test "has many alarm_state_histories" do
    histories = alarms(:flood_alert_belem).alarm_state_histories
    assert_includes histories, alarm_state_histories(:alarm_transition)
  end

  test "destroying alarm destroys dependent alarm_actions" do
    alarm = alarms(:precip_3h_belem)
    action_ids = alarm.alarm_actions.pluck(:id)
    assert action_ids.any?

    alarm.destroy
    assert_empty AlarmAction.where(id: action_ids)
  end

  test "destroying alarm destroys dependent alarm_state_histories" do
    alarm = alarms(:flood_alert_belem)
    history_ids = alarm.alarm_state_histories.pluck(:id)
    assert history_ids.any?

    alarm.destroy
    assert_empty AlarmStateHistory.where(id: history_ids)
  end

  # ── State Machine: transition_to! ──

  test "transition_to! changes state" do
    alarm = alarms(:precip_3h_belem)
    assert_equal "ok", alarm.state

    alarm.transition_to!("alarm", reason: "2 of 3 breached", datapoints: [1, 2, 3], severity: 2)

    assert_equal "alarm", alarm.state
    assert_not_nil alarm.state_changed_at
    assert_equal "2 of 3 breached", alarm.state_reason
  end

  test "transition_to! sets current_severity when transitioning to alarm" do
    alarm = alarms(:precip_3h_belem)
    assert_nil alarm.current_severity

    alarm.transition_to!("alarm", reason: "breached", severity: 3)

    assert_equal 3, alarm.reload.current_severity
  end

  test "transition_to! clears current_severity when transitioning to ok" do
    alarm = alarms(:flood_alert_belem)
    assert_equal 3, alarm.current_severity

    alarm.transition_to!("ok", reason: "recovered")

    assert_nil alarm.reload.current_severity
  end

  test "transition_to! records severity change while already in alarm" do
    alarm = alarms(:flood_alert_belem)
    assert_equal "alarm", alarm.state
    assert_equal 3, alarm.current_severity

    assert_difference "AlarmStateHistory.count", 1 do
      alarm.transition_to!("alarm", reason: "severity downgrade", severity: 2)
    end

    assert_equal 2, alarm.reload.current_severity
    assert_equal "alarm", alarm.state

    history = alarm.alarm_state_histories.order(created_at: :desc).first
    assert_equal "alarm", history.previous_state
    assert_equal "alarm", history.new_state
  end

  test "transition_to! creates alarm_state_history record" do
    alarm = alarms(:precip_3h_belem)

    assert_difference "AlarmStateHistory.count", 1 do
      alarm.transition_to!("alarm", reason: "threshold breached", datapoints: [42.0], severity: 2)
    end

    history = alarm.alarm_state_histories.order(created_at: :desc).first
    assert_equal "ok", history.previous_state
    assert_equal "alarm", history.new_state
    assert_equal "threshold breached", history.reason
    assert_equal [42.0], history.datapoints
    assert_not_nil history.evaluated_at
  end

  test "transition_to! is a no-op when state and severity are unchanged" do
    alarm = alarms(:precip_3h_belem)
    assert_equal "ok", alarm.state

    assert_no_difference "AlarmStateHistory.count" do
      alarm.transition_to!("ok", reason: "still ok")
    end
  end

  test "transition_to! records multiple transitions" do
    alarm = alarms(:precip_3h_belem)

    alarm.transition_to!("alarm", reason: "breached", severity: 2)
    alarm.transition_to!("ok", reason: "recovered")

    histories = alarm.alarm_state_histories.order(:created_at)
    assert_equal 3, histories.count  # 1 existing fixture + 2 new

    latest = histories.last
    assert_equal "alarm", latest.previous_state
    assert_equal "ok", latest.new_state
  end

  # ── Helper methods ──

  test "ok? returns true when state is ok" do
    assert alarms(:precip_3h_belem).ok?
  end

  test "alarm? returns true when state is alarm" do
    assert alarms(:flood_alert_belem).alarm?
  end

  test "insufficient_data? returns true when state is insufficient_data" do
    assert alarms(:disabled_alarm).insufficient_data?
  end

  test "metric? returns true for metric type" do
    assert alarms(:precip_3h_belem).metric?
  end
end
