module RiskHelper
  SEVERITY_LABEL = {
    0 => "Vigilância",
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alarme",
    4 => "Emergência"
  }.freeze

  RISK_LEVEL_LABEL = {
    "normal"     => "Vigilância",
    "attention"  => "Atenção",
    "alert"      => "Alerta",
    "high_alert" => "Alarme",
    "emergency"  => "Emergência"
  }.freeze

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

  ASSESSMENT_LEVEL_LABEL = {
    0 => "Vigilância",
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alarme",
    4 => "Emergência"
  }.freeze

  # Assessment levels add the baseline 0 ("Vigilância") to the firing severities (1..4),
  # reusing the severity colors so the dashboard cards stay visually consistent.
  ASSESSMENT_LEVEL_TEXT_CLASS = SEVERITY_TEXT_CLASS.merge(0 => "text-risk-normal").freeze
  ASSESSMENT_LEVEL_BORDER_CLASS = SEVERITY_BORDER_CLASS.merge(0 => "border-l-risk-normal").freeze

  METRIC_NAME_LABEL = {
    "precipitation"   => "Precipitação",
    "forecast_precip" => "Previsão de Precipitação"
  }.freeze

  READING_TYPE_LABEL = {
    "precipitation" => "Precipitação",
    "temperature"   => "Temperatura",
    "humidity"      => "Umidade"
  }.freeze

  SENSOR_TYPE_LABEL = {
    "pluviometer"     => "Pluviômetro",
    "weather_station" => "Meteorológica"
  }.freeze

  SENSOR_TYPE_BADGE_CLASSES = {
    "pluviometer"     => "bg-sensor-pluviometer/20 text-sensor-pluviometer",
    "weather_station" => "bg-sensor-weather/20 text-sensor-weather"
  }.freeze

  CONNECTION_STATUS_LABEL = {
    "unknown"      => "Sem dados",
    "connected"    => "Conectado",
    "disconnected" => "Desconectado"
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

  # severity 0..4 only — nil is NOT coerced to 0. Vigilância and "no severity" (nil, e.g.
  # insufficient_data) are different things and must never render as the same badge.
  def severity_badge(severity)
    level = severity&.to_i
    tag.span(
      SEVERITY_LABEL[level],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SEVERITY_BADGE_CLASSES[level]}"
    )
  end

  # Like severity_badge, but nil (e.g. an insufficient_data alarm has no current_severity)
  # renders as its own distinct "Dados insuficientes" badge instead of a blank one — nil must
  # never be silently treated as 0/Vigilância, since "we don't know" isn't "confirmed calm".
  def assessment_level_badge(severity)
    return tag.span("Dados insuficientes", class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-zinc-500/20 text-zinc-400") if severity.nil?

    severity_badge(severity)
  end

  def alarm_severity_badge(severity, monitored: true)
    if !monitored
      tag.span("Não monitorada", class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-zinc-500/20 text-zinc-400")
    else
      severity_badge(severity || 0)
    end
  end

  def sensor_type_badge(sensor_type)
    tag.span(
      SENSOR_TYPE_LABEL[sensor_type.to_s],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SENSOR_TYPE_BADGE_CLASSES[sensor_type.to_s]}"
    )
  end

  def comparison_symbol(operator)
    COMPARISON_SYMBOL[operator.to_s] || operator.to_s
  end

  def reading_type_label(reading_type)
    READING_TYPE_LABEL[reading_type.to_s] || reading_type.to_s.humanize
  end

  # Small colored dot + label pairing, shown next to the manual status badge
  # to surface whether a station is actually delivering data right now.
  def connection_status_indicator(connection_status)
    css_class = CONNECTION_STATUS_TEXT_CLASS[connection_status.to_s] || "text-sensor-offline"
    label = CONNECTION_STATUS_LABEL[connection_status.to_s] || connection_status.to_s.humanize

    tag.span(class: "inline-flex items-center gap-1 text-xs #{css_class}") do
      tag.span(class: "inline-block h-1.5 w-1.5 rounded-full bg-current") + tag.span(label)
    end
  end

  def severity_bar_class(severity)
    SEVERITY_BAR_CLASS[severity.to_i] || "bg-zinc-500"
  end
end
