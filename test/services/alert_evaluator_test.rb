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

  test "creates alert when precipitation threshold is breached" do
    # Lower the threshold so fixture data exceeds it
    threshold = alert_thresholds(:precipitation_high)
    threshold.update!(value: 10.0, parameter: "precipitation")

    assert_difference "Alert.count" do
      AlertEvaluator.evaluate(@assessment)
    end

    alert = Alert.where(alert_type: "automatic").order(:created_at).last
    assert_equal "automatic", alert.alert_type
    assert_equal "active", alert.status
    assert_equal threshold.severity, alert.severity
    assert_equal @basin, alert.river_basin
  end

  test "creates alert when river level threshold is breached" do
    sensor = sensors(:fluv_belem)
    SensorReading.create!(
      sensor: sensor,
      value: 1.6,
      unit: "m",
      reading_type: "river_level",
      recorded_at: 2.minutes.ago
    )

    assert_difference "Alert.count" do
      AlertEvaluator.evaluate(@assessment)
    end

    alert = Alert.where(alert_type: "automatic").order(:created_at).last
    assert_equal rivers(:belem), alert.river
  end

  test "does not create alert when cooldown is active" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.update!(value: 10.0, parameter: "precipitation")

    Alert.create!(
      title: "Alerta existente",
      description: "Teste de cooldown",
      severity: threshold.severity,
      alert_type: "automatic",
      status: "active",
      river_basin: @basin,
      alert_threshold: threshold,
      activated_at: Time.current
    )

    # Count alerts from evaluator (only automatic alerts from this threshold)
    before_count = Alert.where(alert_threshold: threshold).count
    AlertEvaluator.evaluate(@assessment)
    after_count = Alert.where(alert_threshold: threshold).count

    assert_equal before_count, after_count
  end

  test "alert has trigger_data with threshold info" do
    threshold = alert_thresholds(:precipitation_high)
    threshold.update!(value: 10.0, parameter: "precipitation")

    AlertEvaluator.evaluate(@assessment)

    alert = Alert.where(alert_threshold: threshold).order(:created_at).last
    assert alert.present?
    assert alert.trigger_data.present?
    assert_equal threshold.id, alert.trigger_data["threshold_id"]
    assert_equal threshold.value, alert.trigger_data["threshold_value"]
  end

  test "does not create alert when threshold is not breached" do
    # Threshold is 60mm, fixture data is ~29mm → no breach
    assert_no_difference "Alert.where(alert_threshold: alert_thresholds(:precipitation_high)).count" do
      AlertEvaluator.evaluate(@assessment)
    end
  end
end
