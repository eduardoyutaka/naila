require "test_helper"

class CompositeRuleParserTest < ActiveSupport::TestCase
  # ── Basic expressions ──

  test "parses ALARM(name)" do
    states = { "precip" => "alarm" }
    assert_equal true, evaluate("ALARM(precip)", states)
  end

  test "parses ALARM(name) returns false when not in alarm" do
    states = { "precip" => "ok" }
    assert_equal false, evaluate("ALARM(precip)", states)
  end

  test "parses OK(name)" do
    states = { "precip" => "ok" }
    assert_equal true, evaluate("OK(precip)", states)
  end

  test "parses INSUFFICIENT_DATA(name)" do
    states = { "precip" => "insufficient_data" }
    assert_equal true, evaluate("INSUFFICIENT_DATA(precip)", states)
  end

  # ── AND ──

  test "AND with both true" do
    states = { "a" => "alarm", "b" => "alarm" }
    assert_equal true, evaluate("ALARM(a) AND ALARM(b)", states)
  end

  test "AND with one false" do
    states = { "a" => "alarm", "b" => "ok" }
    assert_equal false, evaluate("ALARM(a) AND ALARM(b)", states)
  end

  # ── OR ──

  test "OR with one true" do
    states = { "a" => "alarm", "b" => "ok" }
    assert_equal true, evaluate("ALARM(a) OR ALARM(b)", states)
  end

  test "OR with both false" do
    states = { "a" => "ok", "b" => "ok" }
    assert_equal false, evaluate("ALARM(a) OR ALARM(b)", states)
  end

  # ── NOT ──

  test "NOT inverts result" do
    states = { "a" => "ok" }
    assert_equal true, evaluate("NOT ALARM(a)", states)
  end

  test "NOT ALARM when in alarm" do
    states = { "a" => "alarm" }
    assert_equal false, evaluate("NOT ALARM(a)", states)
  end

  # ── Parentheses ──

  test "respects parentheses for precedence" do
    states = { "a" => "alarm", "b" => "ok", "c" => "alarm" }
    # a AND (b OR c) → true AND (false OR true) → true
    assert_equal true, evaluate("ALARM(a) AND (ALARM(b) OR ALARM(c))", states)
  end

  test "nested parentheses" do
    states = { "a" => "alarm", "b" => "alarm" }
    assert_equal true, evaluate("(ALARM(a) AND ALARM(b))", states)
  end

  # ── Complex expressions ──

  test "three-way AND" do
    states = { "a" => "alarm", "b" => "alarm", "c" => "alarm" }
    assert_equal true, evaluate("ALARM(a) AND ALARM(b) AND ALARM(c)", states)
  end

  test "mixed AND/OR with correct precedence" do
    states = { "a" => "alarm", "b" => "ok", "c" => "alarm" }
    # AND binds tighter than OR: a AND b OR c → (a AND b) OR c → false OR true → true
    assert_equal true, evaluate("ALARM(a) AND ALARM(b) OR ALARM(c)", states)
  end

  test "names with underscores and numbers" do
    states = { "precip_3h_belem" => "alarm" }
    assert_equal true, evaluate("ALARM(precip_3h_belem)", states)
  end

  # ── Error handling ──

  test "raises error on empty expression" do
    assert_raises(CompositeRuleParser::ParseError) do
      CompositeRuleParser.parse("")
    end
  end

  test "raises error on invalid syntax" do
    assert_raises(CompositeRuleParser::ParseError) do
      CompositeRuleParser.parse("INVALID(x)")
    end
  end

  test "raises error on unmatched parenthesis" do
    assert_raises(CompositeRuleParser::ParseError) do
      CompositeRuleParser.parse("(ALARM(x)")
    end
  end

  # ── Validation helper ──

  test "valid? returns true for valid rule" do
    assert CompositeRuleParser.valid?("ALARM(x) AND ALARM(y)")
  end

  test "valid? returns false for invalid rule" do
    assert_not CompositeRuleParser.valid?("BROKEN!")
  end

  private

  def evaluate(rule, states)
    tree = CompositeRuleParser.parse(rule)
    tree.evaluate(states)
  end
end
