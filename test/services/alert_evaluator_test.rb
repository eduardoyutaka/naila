require "test_helper"

class AlertEvaluatorTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
    @assessment = RiskAssessment.create!(
      river_basin: @basin,
      assessed_at: Time.current,
      risk_level: 3,
      risk_score: 0.72,
      precipitation_score: 0.8,
      river_level_score: 0.6,
      forecast_score: 0.7,
      soil_moisture_score: 0.5,
      contributing_factors: { precipitation: 0.8, river_level: 0.6 }
    )
  end

  # ── Alert creation ──

  test "creates alert at highest breached severity for river level" do
    # Fixture river level is 1.2m — add higher reading that breaches sev 1 (1.2m) and sev 2 (1.5m)
    add_river_reading(1.8)

    assert_difference "river_alerts.count", 1 do
      AlertEvaluator.evaluate(@assessment)
    end

    alert = river_alerts.order(:created_at).last
    assert_equal 2, alert.severity
    assert_equal rivers(:belem), alert.river
    assert_equal @basin, alert.river_basin
  end

  test "creates alert at highest breached severity for precipitation" do
    # Fixture 3h precipitation is ~23.8mm — breaches sev 1 (20mm) only
    results = AlertEvaluator.evaluate(@assessment)

    precipitation_results = results.select { |r| r[:alert].alert_threshold&.parameter == "precipitation" }
    assert_equal 1, precipitation_results.count

    alert = precipitation_results.first[:alert]
    assert_equal 1, alert.severity
    assert_equal :created, precipitation_results.first[:action]
  end

  test "creates single alert per parameter group, not one per threshold" do
    add_river_reading(1.8)  # breaches sev 1 and sev 2

    assert_difference "river_alerts.count", 1 do
      AlertEvaluator.evaluate(@assessment)
    end
  end

  test "returns result hash with action :created for new alerts" do
    add_river_reading(1.8)

    results = AlertEvaluator.evaluate(@assessment)
    river_result = results.find { |r| r[:alert].river == rivers(:belem) }

    assert_not_nil river_result
    assert_equal :created, river_result[:action]
  end

  test "alert trigger_data contains threshold and current value info" do
    add_river_reading(1.8)

    AlertEvaluator.evaluate(@assessment)

    alert = Alert.where(alert_type: "automatic", river_id: rivers(:belem).id).last
    assert alert.trigger_data.present?
    assert_equal @assessment.risk_score, alert.trigger_data["risk_score"]
    assert_equal "river_level", alert.trigger_data["parameter"]
  end

  # ── Severity escalation ──

  test "escalates existing alert when readings increase" do
    existing = create_river_alert(severity: 1, threshold: alert_thresholds(:river_level_attention))
    add_river_reading(1.8)  # now breaches sev 2 (1.5m)

    results = AlertEvaluator.evaluate(@assessment)

    existing.reload
    assert_equal 2, existing.severity
    assert_equal 1, results.select { |r| r[:action] == :updated }.count
    assert_equal 1, results.find { |r| r[:action] == :updated }[:from_severity]
  end

  test "records severity change history in trigger_data" do
    existing = create_river_alert(severity: 1, threshold: alert_thresholds(:river_level_attention))
    add_river_reading(1.8)

    AlertEvaluator.evaluate(@assessment)

    existing.reload
    changes = existing.trigger_data["severity_changes"]
    assert_equal 1, changes.length
    assert_equal 1, changes.first["from"]
    assert_equal 2, changes.first["to"]
  end

  test "returns result hash with action :updated and from_severity" do
    existing = create_river_alert(severity: 1, threshold: alert_thresholds(:river_level_attention))
    add_river_reading(1.8)

    results = AlertEvaluator.evaluate(@assessment)
    result = results.find { |r| r[:action] == :updated }

    assert_not_nil result
    assert_equal 1, result[:from_severity]
    assert_equal 2, result[:alert].severity
  end

  # ── Severity de-escalation ──

  test "de-escalates existing alert when readings decrease" do
    existing = create_river_alert(severity: 2, threshold: alert_thresholds(:river_level_alert))
    # fixture river level is 1.2m — breaches sev 1 (1.2m) but not sev 2 (1.5m)

    results = AlertEvaluator.evaluate(@assessment)

    existing.reload
    assert_equal 1, existing.severity
    assert_equal 1, results.select { |r| r[:action] == :updated }.count
  end

  test "does not emit :updated result when severity is unchanged" do
    existing = create_river_alert(severity: 1, threshold: alert_thresholds(:river_level_attention))
    # fixture river level is 1.2m — breaches sev 1 only (same as existing severity)

    results = AlertEvaluator.evaluate(@assessment)

    existing.reload
    assert_equal 1, existing.severity
    assert_empty results.select { |r| r[:action] == :updated }
  end

  # ── Auto-resolve ──

  test "auto-resolves existing alert when readings drop below all thresholds" do
    existing = create_river_alert(severity: 1, threshold: alert_thresholds(:river_level_attention))
    add_river_reading(0.8)  # below all thresholds (sev 1 is 1.2m gte)

    results = AlertEvaluator.evaluate(@assessment)

    existing.reload
    assert_equal "resolved", existing.status
    assert_equal 1, results.select { |r| r[:action] == :resolved }.count
  end

  test "returns result hash with action :resolved and from_severity" do
    existing = create_river_alert(severity: 2, threshold: alert_thresholds(:river_level_alert))
    add_river_reading(0.8)

    results = AlertEvaluator.evaluate(@assessment)
    result = results.find { |r| r[:action] == :resolved }

    assert_not_nil result
    assert_equal 2, result[:from_severity]
    assert_equal "resolved", result[:alert].status
  end

  # ── Cooldown after resolution ──

  test "does not create alert when recently resolved" do
    Alert.create!(
      title: "Alerta resolvido",
      description: "Teste cooldown",
      severity: 1,
      alert_type: "automatic",
      status: "resolved",
      river_basin: @basin,
      river: rivers(:belem),
      alert_threshold: alert_thresholds(:river_level_attention),
      activated_at: 2.hours.ago,
      resolved_at: 5.minutes.ago  # within 60min cooldown
    )
    add_river_reading(1.8)

    assert_no_difference "river_alerts.count" do
      AlertEvaluator.evaluate(@assessment)
    end
  end

  test "creates new alert after cooldown expires" do
    Alert.create!(
      title: "Alerta resolvido",
      description: "Teste cooldown expirado",
      severity: 1,
      alert_type: "automatic",
      status: "resolved",
      river_basin: @basin,
      river: rivers(:belem),
      alert_threshold: alert_thresholds(:river_level_attention),
      activated_at: 3.hours.ago,
      resolved_at: 90.minutes.ago  # beyond 60min cooldown
    )
    add_river_reading(1.8)

    assert_difference "river_alerts.count", 1 do
      AlertEvaluator.evaluate(@assessment)
    end
  end

  # ── No duplicates ──

  test "does not create duplicate alerts on second evaluation with same readings" do
    add_river_reading(1.8)

    AlertEvaluator.evaluate(@assessment)

    assert_no_difference "Alert.count" do
      AlertEvaluator.evaluate(@assessment)
    end
  end

  # ── Multiple parameter groups ──

  test "creates independent alerts for precipitation and river level" do
    add_river_reading(1.8)  # breaches river level thresholds
    # fixture precipitation ~23.8mm breaches precipitation_attention

    before = Alert.where(alert_type: "automatic").count

    AlertEvaluator.evaluate(@assessment)

    after = Alert.where(alert_type: "automatic").count
    assert_equal 2, after - before
  end

  # ── Does not affect manual alerts ──

  test "does not modify manual alerts even when readings match threshold" do
    manual = Alert.create!(
      title: "Manual",
      description: "Manual alert",
      severity: 1,
      alert_type: "manual",
      status: "active",
      river_basin: @basin,
      river: rivers(:belem),
      activated_at: 1.hour.ago
    )
    add_river_reading(0.8)  # would trigger auto-resolve if automatic

    AlertEvaluator.evaluate(@assessment)

    manual.reload
    assert_equal "active", manual.status
    assert_equal 1, manual.severity
  end

  private

  def river_alerts
    Alert.where(alert_type: "automatic", river_id: rivers(:belem).id)
  end

  def add_river_reading(value)
    SensorReading.create!(
      sensor: sensors(:fluv_belem),
      value: value,
      unit: "m",
      reading_type: "river_level",
      recorded_at: 1.minute.ago
    )
  end

  def create_river_alert(severity:, threshold:)
    Alert.create!(
      title: "Nível do rio acima do limiar",
      description: "Teste de severidade dinâmica",
      severity: severity,
      alert_type: "automatic",
      status: "active",
      river_basin: @basin,
      river: rivers(:belem),
      alert_threshold: threshold,
      activated_at: 30.minutes.ago,
      trigger_data: {}
    )
  end
end
