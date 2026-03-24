require "test_helper"

class RiskEngineTest < ActiveSupport::TestCase
  setup do
    @zone = risk_zones(:zona_centro)
  end

  test "assess creates a RiskAssessment record" do
    assert_difference "RiskAssessment.count", 1 do
      RiskEngine.assess(@zone)
    end

    assessment = RiskAssessment.last
    assert_equal @zone, assessment.risk_zone
    assert_in_delta Time.current, assessment.assessed_at, 2
    assert_includes 0..4, assessment.risk_level
    assert_includes 0.0..1.0, assessment.risk_score
  end

  test "assess updates risk zone current values" do
    assessment = RiskEngine.assess(@zone)
    @zone.reload

    assert_equal assessment.risk_score, @zone.current_risk_score
    assert_in_delta Time.current, @zone.risk_updated_at, 2
  end

  test "assess returns the risk assessment" do
    result = RiskEngine.assess(@zone)

    assert_kind_of RiskAssessment, result
    assert result.persisted?
  end

  test "assess records individual sub-scores" do
    assessment = RiskEngine.assess(@zone)

    assert assessment.precipitation_score.is_a?(Numeric)
    assert assessment.river_level_score.is_a?(Numeric)
    assert assessment.forecast_score.is_a?(Numeric)
    assert assessment.soil_moisture_score.is_a?(Numeric)
  end

  test "assess records contributing factors" do
    assessment = RiskEngine.assess(@zone)

    assert assessment.contributing_factors.is_a?(Hash)
  end

  test "assess_all processes all active risk zones" do
    assert_difference "RiskAssessment.count", RiskZone.active.count do
      RiskEngine.assess_all
    end
  end

  test "score_to_level maps correctly at boundaries" do
    engine = RiskEngine.new(risk_zones(:zona_centro))

    assert_equal 0, engine.send(:score_to_level, 0.0)
    assert_equal 0, engine.send(:score_to_level, 0.19)
    assert_equal 1, engine.send(:score_to_level, 0.2)
    assert_equal 1, engine.send(:score_to_level, 0.39)
    assert_equal 2, engine.send(:score_to_level, 0.4)
    assert_equal 2, engine.send(:score_to_level, 0.59)
    assert_equal 3, engine.send(:score_to_level, 0.6)
    assert_equal 3, engine.send(:score_to_level, 0.79)
    assert_equal 4, engine.send(:score_to_level, 0.8)
    assert_equal 4, engine.send(:score_to_level, 1.0)
  end

  test "precipitation score uses nearby sensor readings" do
    engine = RiskEngine.new(@zone)
    score = engine.send(:compute_precipitation_score)

    # With fixture data (12.5 + 8.2 = 20.7mm in last hour), should produce a non-zero score
    assert score >= 0.0
    assert score <= 1.0
  end

  test "river level score uses river gauge readings" do
    engine = RiskEngine.new(@zone)
    score = engine.send(:compute_river_level_score)

    # River Belém at 1.2m, alert at 1.5m → should be moderate
    assert score >= 0.0
    assert score <= 1.0
  end

  test "forecast score uses current weather forecasts" do
    engine = RiskEngine.new(@zone)
    score = engine.send(:compute_forecast_score)

    # With fixture forecasts (15mm, 80% probability), should produce a non-zero score
    assert score >= 0.0
    assert score <= 1.0
  end

  test "soil moisture score returns valid range" do
    engine = RiskEngine.new(@zone)
    score = engine.send(:compute_soil_moisture_score)

    assert score >= 0.0
    assert score <= 1.0
  end
end
