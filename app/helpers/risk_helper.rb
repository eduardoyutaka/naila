module RiskHelper
  SEVERITY_LABEL = {
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
    1 => "text-risk-attention",
    2 => "text-risk-alert",
    3 => "text-risk-high",
    4 => "text-risk-emergency"
  }.freeze

  SEVERITY_BORDER_CLASS = {
    1 => "border-l-risk-attention",
    2 => "border-l-risk-alert",
    3 => "border-l-risk-high",
    4 => "border-l-risk-emergency"
  }.freeze

  SEVERITY_BADGE_CLASSES = {
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

  ASSESSMENT_LEVEL_BADGE_CLASSES = {
    0 => "bg-risk-normal/20 text-risk-normal",
    1 => "bg-risk-attention/20 text-risk-attention",
    2 => "bg-risk-alert/20 text-risk-alert",
    3 => "bg-risk-high/20 text-risk-high",
    4 => "bg-risk-emergency/20 text-risk-emergency"
  }.freeze

  # Assessment levels add the baseline 0 ("Vigilância") to the firing severities (1..4),
  # reusing the severity colors so the dashboard cards stay visually consistent.
  ASSESSMENT_LEVEL_TEXT_CLASS = SEVERITY_TEXT_CLASS.merge(0 => "text-risk-normal").freeze
  ASSESSMENT_LEVEL_BORDER_CLASS = SEVERITY_BORDER_CLASS.merge(0 => "border-l-risk-normal").freeze

  METRIC_NAME_LABEL = {
    "precipitation_3h"  => "Precipitação (3h)",
    "precipitation_1h"  => "Precipitação (1h)",
    "precipitation_24h" => "Precipitação (24h)",
    "soil_moisture"     => "Umidade do solo",
    "temperature"       => "Temperatura",
    "humidity"          => "Umidade relativa"
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

  def severity_badge(severity)
    tag.span(
      SEVERITY_LABEL[severity.to_i],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SEVERITY_BADGE_CLASSES[severity.to_i]}"
    )
  end

  def alarm_severity_badge(severity, monitored: true)
    if !monitored
      tag.span("Não monitorada", class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-zinc-500/20 text-zinc-400")
    elsif severity.to_i.zero?
      tag.span("Vigilância", class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium bg-risk-normal/20 text-risk-normal")
    else
      severity_badge(severity)
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

  def severity_bar_class(severity)
    SEVERITY_BAR_CLASS[severity.to_i] || "bg-zinc-500"
  end
end
