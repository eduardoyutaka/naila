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

  test "connection_status_indicator shows the plain Conectado badge when not stale" do
    html = connection_status_indicator("connected", stale: false)
    assert_includes html, "Conectado"
    assert_not_includes html, "sem leitura recente"
    assert_includes html, "text-sensor-online"
  end

  test "connection_status_indicator defaults to not stale when the flag is omitted" do
    assert_includes connection_status_indicator("connected"), "Conectado"
  end

  test "connection_status_indicator shows the amber stale variant when connected and stale" do
    html = connection_status_indicator("connected", stale: true)
    assert_includes html, "Conectado (sem leitura recente)"
    assert_includes html, "text-risk-attention"
  end

  test "connection_status_indicator ignores the stale flag for disconnected/unknown" do
    disconnected = connection_status_indicator("disconnected", stale: true)
    assert_includes disconnected, "Desconectado"
    assert_not_includes disconnected, "sem leitura recente"

    unknown = connection_status_indicator("unknown", stale: true)
    assert_includes unknown, "Sem dados"
    assert_not_includes unknown, "sem leitura recente"
  end
end
