require "test_helper"

class RiskEngineTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
  end

  test "assess creates a RiskAssessment record" do
    assert_difference "RiskAssessment.count", 1 do
      RiskEngine.assess(@basin)
    end

    assessment = RiskAssessment.last
    assert_equal @basin, assessment.river_basin
    assert_in_delta Time.current, assessment.assessed_at, 2
    assert_includes 0..4, assessment.risk_level
    assert_includes 0.0..1.0, assessment.risk_score
  end

  test "assess updates river basin current values" do
    assessment = RiskEngine.assess(@basin)
    @basin.reload

    assert_equal assessment.risk_score, @basin.current_risk_score
    assert_in_delta Time.current, @basin.risk_updated_at, 2
  end

  test "assess returns the risk assessment" do
    result = RiskEngine.assess(@basin)

    assert_kind_of RiskAssessment, result
    assert result.persisted?
  end

  test "assess records individual sub-scores" do
    assessment = RiskEngine.assess(@basin)

    assert assessment.precipitation_score.is_a?(Numeric)
    assert assessment.forecast_score.is_a?(Numeric)
    assert assessment.soil_moisture_score.is_a?(Numeric)
  end

  test "assess records contributing factors" do
    assessment = RiskEngine.assess(@basin)

    assert assessment.contributing_factors.is_a?(Hash)
  end

  test "assess_all processes all active river basins" do
    assert_difference "RiskAssessment.count", RiverBasin.active.count do
      RiskEngine.assess_all
    end
  end

  test "score_to_level maps correctly at boundaries" do
    engine = RiskEngine.new(river_basins(:bacia_belem))

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
    engine = RiskEngine.new(@basin)
    score = engine.send(:compute_precipitation_score)

    assert score >= 0.0
    assert score <= 1.0
  end

  test "forecast score uses current weather forecasts" do
    engine = RiskEngine.new(@basin)
    score = engine.send(:compute_forecast_score)

    assert score >= 0.0
    assert score <= 1.0
  end

  test "soil moisture score returns valid range" do
    engine = RiskEngine.new(@basin)
    score = engine.send(:compute_soil_moisture_score)

    assert score >= 0.0
    assert score <= 1.0
  end
end
