require "test_helper"

class RiskHelperTest < ActionView::TestCase
  test "comparison_symbol maps CloudWatch operator strings to math symbols" do
    assert_equal ">",  comparison_symbol("GreaterThanThreshold")
    assert_equal "≥",  comparison_symbol("GreaterThanOrEqualToThreshold")
    assert_equal "<",  comparison_symbol("LessThanThreshold")
    assert_equal "≤",  comparison_symbol("LessThanOrEqualToThreshold")
  end

  test "comparison_symbol falls back to the input for unknown operators" do
    assert_equal "Whatever", comparison_symbol("Whatever")
    assert_equal "",         comparison_symbol(nil)
  end

  test "assessment_level_badge shows Vigilância for an explicit severity 0" do
    assert_includes assessment_level_badge(0), "Vigilância"
    assert_includes assessment_level_badge(0), "bg-risk-normal"
  end

  test "assessment_level_badge shows a distinct label for nil (insufficient data)" do
    # nil means "we don't have enough data to evaluate", not "confirmed calm" —
    # conflating them would let an operator mistake a data outage for an all-clear.
    assert_includes assessment_level_badge(nil), "Dados insuficientes"
    assert_not_includes assessment_level_badge(nil), "Vigilância"
  end

  test "severity_badge labels the Vigilância baseline for an explicit severity 0" do
    assert_includes severity_badge(0), "Vigilância"
    assert_includes severity_badge(0), "bg-risk-normal"
  end

  test "assessment_level_badge labels the firing severities 1-4" do
    assert_includes assessment_level_badge(1), "Atenção"
    assert_includes assessment_level_badge(3), "Alarme"
    assert_includes assessment_level_badge(4), "Emergência"
  end
end
