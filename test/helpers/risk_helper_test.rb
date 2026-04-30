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
end
