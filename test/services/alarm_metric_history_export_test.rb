require "test_helper"

class AlarmMetricHistoryExportTest < ActiveSupport::TestCase
  setup do
    @alarm = Alarm.new(name: "Alerta Teste", description: "Descrição do alarme de teste")
    @alarm.alarm_thresholds.build(severity: 1, comparison_operator: "GreaterThanOrEqualToThreshold",
                                   threshold_value: 10.0, unit: "mm")
    @alarm.alarm_thresholds.build(severity: 2, comparison_operator: "GreaterThanOrEqualToThreshold",
                                   threshold_value: 25.0, unit: "mm")

    @from = Time.zone.parse("2026-10-01 00:00")
    @to   = Time.zone.parse("2026-10-01 03:00")
    @series = [
      { period_end: @from,            value: 5.0 },  # breaches nothing
      { period_end: @from + 1.hour,   value: 15.0 }, # breaches severity 1
      { period_end: @from + 2.hours,  value: 30.0 }, # breaches severity 2
      { period_end: @to,              value: nil }    # missing data
    ]
  end

  def rows
    AlarmMetricHistoryExport.build(alarm: @alarm, series: @series, from: @from, to: @to)
      .workbook.worksheets.first.rows
  end

  test "first row is the alarm name" do
    assert_equal [ "Alerta Teste" ], rows[0].cells.map(&:value)
  end

  test "second row is the alarm description" do
    assert_equal [ "Descrição do alarme de teste" ], rows[1].cells.map(&:value)
  end

  test "skips the description row when the alarm has none" do
    @alarm.description = nil
    values = rows.map { |r| r.cells.map(&:value) }
    assert_not_includes values, [ nil ]
  end

  test "includes a threshold legend row per alarm_threshold, ordered by severity" do
    values = rows.map { |r| r.cells.map(&:value) }
    sev1_row = values.find { |v| v.first == I18n.t("enums.severity.1") }
    sev2_row = values.find { |v| v.first == I18n.t("enums.severity.2") }
    refute_nil sev1_row
    refute_nil sev2_row
    assert_match(/10\.0/, sev1_row.last)
    assert_match(/25\.0/, sev2_row.last)
  end

  test "data table header names the alarm's unit" do
    values = rows.map { |r| r.cells.map(&:value) }
    assert_includes values, [ "Data/Hora", "Valor (mm)" ]
  end

  test "writes every datapoint with its real timestamp and value" do
    values = rows.map { |r| r.cells.map(&:value) }
    assert_includes values, [ @from, 5.0 ]
    assert_includes values, [ @from + 1.hour, 15.0 ]
    assert_includes values, [ @from + 2.hours, 30.0 ]
    assert_includes values, [ @to, nil ]
  end

  test "colors a datapoint cell to match the severity band it breaches" do
    data_rows = rows.last(4)
    value_styles = data_rows.map { |r| r.cells[1].style }

    no_breach_style, sev1_style, sev2_style, missing_style = value_styles

    assert_equal 0, no_breach_style, "a value breaching nothing should carry no special style"
    assert_equal 0, missing_style, "a missing value should carry no special style"
    refute_equal 0, sev1_style
    refute_equal 0, sev2_style
    refute_equal sev1_style, sev2_style, "different severities must be visually distinguishable"
  end

  test "omits the threshold legend and period row when there is nothing to export" do
    alarm = Alarm.new(name: "Sem Dados")
    values = AlarmMetricHistoryExport.build(alarm: alarm, series: [], from: nil, to: nil)
      .workbook.worksheets.first.rows.map { |r| r.cells.map(&:value) }

    assert_not_includes values.flatten.compact, I18n.t("enums.severity.1")
    assert_includes values, [ "Data/Hora", "Valor" ]
  end
end
