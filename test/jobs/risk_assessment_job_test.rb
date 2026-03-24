require "test_helper"

class RiskAssessmentJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "assesses a single risk zone by id" do
    zone = risk_zones(:zona_centro)

    assert_difference "RiskAssessment.count", 1 do
      RiskAssessmentJob.perform_now(zone.id)
    end
  end

  test "assesses all active risk zones with 'all' scope" do
    assert_difference "RiskAssessment.count", RiskZone.active.count do
      RiskAssessmentJob.perform_now("all")
    end
  end

  test "evaluates alerts after assessment" do
    zone = risk_zones(:zona_centro)
    # Lower threshold so it triggers
    alert_thresholds(:precipitation_high).update!(value: 5.0, parameter: "precipitation")

    RiskAssessmentJob.perform_now(zone.id)

    # Should have created at least one automatic alert
    assert Alert.where(alert_type: "automatic", risk_zone: zone).exists?
  end
end
