require "test_helper"

class RiskAssessmentJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "assesses a single river basin by id" do
    basin = river_basins(:bacia_belem)

    assert_difference "RiskAssessment.count", 1 do
      RiskAssessmentJob.perform_now(basin.id)
    end
  end

  test "assesses all active river basins with 'all' scope" do
    assert_difference "RiskAssessment.count", RiverBasin.active.count do
      RiskAssessmentJob.perform_now("all")
    end
  end

  test "evaluates alerts after assessment" do
    basin = river_basins(:bacia_belem)
    # Lower threshold so it triggers
    alert_thresholds(:precipitation_high).update!(value: 5.0, parameter: "precipitation")

    RiskAssessmentJob.perform_now(basin.id)

    # Should have created at least one automatic alert
    assert Alert.where(alert_type: "automatic", river_basin: basin).exists?
  end

  test "enqueues alarm evaluation after risk assessment" do
    assert_enqueued_with(job: AlarmEvaluationJob, args: [ "all" ]) do
      RiskAssessmentJob.perform_now("all")
    end
  end
end
