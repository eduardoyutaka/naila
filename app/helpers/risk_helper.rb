module RiskHelper
  SEVERITY_TEXT_CLASS = {
    0 => "text-risk-normal",
    1 => "text-risk-attention",
    2 => "text-risk-alert",
    3 => "text-risk-high",
    4 => "text-risk-emergency"
  }.freeze

  SEVERITY_BORDER_CLASS = {
    0 => "border-l-risk-normal",
    1 => "border-l-risk-attention",
    2 => "border-l-risk-alert",
    3 => "border-l-risk-high",
    4 => "border-l-risk-emergency"
  }.freeze

  SEVERITY_BADGE_CLASSES = {
    0 => "bg-risk-normal/20 text-risk-normal",
    1 => "bg-risk-attention/20 text-risk-attention",
    2 => "bg-risk-alert/20 text-risk-alert",
    3 => "bg-risk-high/20 text-risk-high",
    4 => "bg-risk-emergency/20 text-risk-emergency"
  }.freeze

  RISK_LEVEL_BADGE_CLASSES = {
    "normal"     => "bg-risk-normal/20 text-risk-normal",
    "attention"  => "bg-risk-attention/20 text-risk-attention",
    "alert"      => "bg-risk-alert/20 text-risk-alert",
    "high_alert" => "bg-risk-high/20 text-risk-high",
    "emergency"  => "bg-risk-emergency/20 text-risk-emergency"
  }.freeze

  # Assessment levels add the baseline 0 ("Vigilância") to the firing severities (1..4),
  # reusing the severity colors so the dashboard cards stay visually consistent.
  ASSESSMENT_LEVEL_TEXT_CLASS = SEVERITY_TEXT_CLASS.merge(0 => "text-risk-normal").freeze
  ASSESSMENT_LEVEL_BORDER_CLASS = SEVERITY_BORDER_CLASS.merge(0 => "border-l-risk-normal").freeze

  SENSOR_TYPE_BADGE_CLASSES = {
    "pluviometer"     => "bg-sensor-pluviometer/20 text-sensor-pluviometer",
    "weather_station" => "bg-sensor-weather/20 text-sensor-weather"
  }.freeze

  CONNECTION_STATUS_TEXT_CLASS = {
    "unknown"      => "text-zinc-500 dark:text-zinc-400",
    "connected"    => "text-sensor-online",
    "disconnected" => "text-sensor-offline"
  }.freeze

  COMPARISON_SYMBOL = {
    "GreaterThanThreshold"          => ">",
    "GreaterThanOrEqualToThreshold" => "≥",
    "LessThanThreshold"             => "<",
    "LessThanOrEqualToThreshold"    => "≤"
  }.freeze

  SEVERITY_BAR_CLASS = {
    1 => "bg-risk-attention",
    2 => "bg-risk-alert",
    3 => "bg-risk-high",
    4 => "bg-risk-emergency"
  }.freeze

  # The full assessment scale (0..4) — not a translation, just the domain range used to
  # iterate severity cards/badges in order. Labels come from I18n (enums.severity.*).
  ASSESSMENT_LEVELS = (0..4).freeze

  # severity 0..4 only — nil is NOT coerced to 0. Vigilância and "no severity" (nil, e.g.
  # insufficient_data) are different things and must never render as the same badge.
  def severity_badge(severity)
    level = severity&.to_i
    tag.span(
      I18n.t("enums.severity.#{level}", default: nil),
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SEVERITY_BADGE_CLASSES[level]}"
    )
  end

  # Like severity_badge, but nil (e.g. an insufficient_data alarm has no current_severity)
  # renders as its own distinct "Dados insuficientes" badge instead of a blank one — nil must
  # never be silently treated as 0/Vigilância, since "we don't know" isn't "confirmed calm".
  def assessment_level_badge(severity)
    return tag.span(I18n.t("labels.insufficient_data_badge"), class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-zinc-500/20 text-zinc-400") if severity.nil?

    severity_badge(severity)
  end

  def alarm_severity_badge(severity, monitored: true)
    if !monitored
      tag.span(I18n.t("labels.not_monitored"), class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-zinc-500/20 text-zinc-400")
    else
      severity_badge(severity || 0)
    end
  end

  def sensor_type_badge(sensor_type)
    tag.span(
      I18n.t("enums.sensor_type.#{sensor_type}", default: sensor_type.to_s.humanize),
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SENSOR_TYPE_BADGE_CLASSES[sensor_type.to_s]}"
    )
  end

  def comparison_symbol(operator)
    COMPARISON_SYMBOL[operator.to_s] || operator.to_s
  end

  def reading_type_label(reading_type)
    I18n.t("enums.reading_type.#{reading_type}", default: reading_type.to_s.humanize)
  end

  def statistic_label(statistic)
    I18n.t("enums.statistic.#{statistic}", default: statistic.to_s)
  end

  # Small colored dot + label pairing, shown next to the manual status badge
  # to surface whether a station is actually delivering data right now.
  # stale: true only changes anything when connection_status is "connected" — a station
  # that's genuinely disconnected/unknown already communicates the problem on its own.
  def connection_status_indicator(connection_status, stale: false)
    if connection_status.to_s == "connected" && stale
      css_class = "text-risk-attention"
      label = I18n.t("labels.connected_stale")
    else
      css_class = CONNECTION_STATUS_TEXT_CLASS[connection_status.to_s] || "text-sensor-offline"
      label = I18n.t("enums.connection_status.#{connection_status}", default: connection_status.to_s.humanize)
    end

    tag.span(class: "inline-flex items-center gap-1 text-xs #{css_class}") do
      tag.span(class: "inline-block h-1.5 w-1.5 rounded-full bg-current") + tag.span(label)
    end
  end

  def severity_bar_class(severity)
    SEVERITY_BAR_CLASS[severity.to_i] || "bg-zinc-500"
  end
end
