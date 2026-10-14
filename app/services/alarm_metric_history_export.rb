require "axlsx"

# Builds the "Histórico da Métrica" XLSX export: the alarm's name/description, its
# threshold bands as a colored legend, and the chart's own bucketed series — with each
# datapoint's value cell colored to the severity band it breaches, so a reader can spot
# which points are concerning without re-reading the thresholds for every row.
class AlarmMetricHistoryExport
  # Mirrors the dashboard's risk-* Tailwind tokens (app/assets/tailwind/application.css)
  # so the exported file visually matches the severity colors used on the map/badges.
  SEVERITY_COLORS = {
    1 => "EAB308", # risk-attention
    2 => "F97316", # risk-alert
    3 => "EF4444", # risk-high
    4 => "A855F7"  # risk-emergency
  }.freeze

  COMPARISON_LABELS = {
    "GreaterThanThreshold" => ">",
    "GreaterThanOrEqualToThreshold" => "≥",
    "LessThanThreshold" => "<",
    "LessThanOrEqualToThreshold" => "≤"
  }.freeze

  def self.build(alarm:, series:, from:, to:)
    new(alarm: alarm, series: series, from: from, to: to).build
  end

  def initialize(alarm:, series:, from:, to:)
    @alarm = alarm
    @series = series
    @from = from
    @to = to
  end

  # Fixed, data-table-sized widths — wide enough for "dd/mm/yyyy hh:mm" and typical
  # legend/value text. Axlsx's automatic bestFit sizes a column to its single longest
  # cell, so without this an arbitrarily long alarm name/description (one free-text
  # cell, merged across both columns) would balloon column A to fit that one line
  # instead of the actual data table underneath it.
  COLUMN_WIDTHS = [ 20, 16 ].freeze

  def build
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Histórico") do |sheet|
      @styles = package.workbook.styles
      add_header(sheet)
      add_threshold_legend(sheet)
      add_data_table(sheet)
      sheet.column_widths(*COLUMN_WIDTHS)
    end
    package
  end

  private

  def add_header(sheet)
    sheet.add_row [ @alarm.name ], style: @styles.add_style(b: true, sz: 13)
    sheet.merge_cells("A#{sheet.rows.size}:B#{sheet.rows.size}")

    if @alarm.description.present?
      sheet.add_row [ @alarm.description ], style: @styles.add_style(i: true, fg_color: "6B7280")
      sheet.merge_cells("A#{sheet.rows.size}:B#{sheet.rows.size}")
    end

    sheet.add_row []

    if @from && @to
      sheet.add_row [ "Período", "#{I18n.l(@from, format: :short)} a #{I18n.l(@to, format: :short)}" ]
      sheet.add_row []
    end
  end

  def add_threshold_legend(sheet)
    return if @alarm.alarm_thresholds.empty?

    sheet.add_row [ "Limiares" ], style: @styles.add_style(b: true)
    sheet.merge_cells("A#{sheet.rows.size}:B#{sheet.rows.size}")

    @alarm.alarm_thresholds.sort_by(&:severity).each do |threshold|
      legend_style = @styles.add_style(bg_color: SEVERITY_COLORS[threshold.severity], fg_color: "FFFFFF", b: true)
      sheet.add_row [
        I18n.t("enums.severity.#{threshold.severity}"),
        "#{COMPARISON_LABELS[threshold.comparison_operator]} #{threshold.threshold_value}#{threshold.unit}"
      ], style: [ legend_style, legend_style ]
    end
    sheet.add_row []
  end

  def add_data_table(sheet)
    unit = @alarm.alarm_thresholds.first&.unit
    value_header = unit.present? ? "Valor (#{unit})" : "Valor"
    date_style = @styles.add_style(format_code: "dd/mm/yyyy hh:mm")
    severity_styles = SEVERITY_COLORS.transform_values { |hex| @styles.add_style(bg_color: hex) }

    sheet.add_row [ "Data/Hora", value_header ], style: @styles.add_style(b: true, bg_color: "E5E7EB")

    @series.each do |pt|
      severity = pt[:value].nil? ? 0 : @alarm.breaching_severity_for(pt[:value])
      sheet.add_row [ pt[:period_end], pt[:value] ],
        style: [ date_style, severity_styles[severity] ],
        types: [ :time, :float ]
    end
  end
end
