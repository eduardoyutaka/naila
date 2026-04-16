module RiskHelper
  SEVERITY_LABEL = {
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alerta Máximo",
    4 => "Emergência"
  }.freeze

  RISK_LEVEL_LABEL = {
    "normal"     => "Normal",
    "attention"  => "Atenção",
    "alert"      => "Alerta",
    "high_alert" => "Alerta Máximo",
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
    0 => "Normal",
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alerta Máximo",
    4 => "Emergência"
  }.freeze

  ASSESSMENT_LEVEL_BADGE_CLASSES = {
    0 => "bg-risk-normal/20 text-risk-normal",
    1 => "bg-risk-attention/20 text-risk-attention",
    2 => "bg-risk-alert/20 text-risk-alert",
    3 => "bg-risk-high/20 text-risk-high",
    4 => "bg-risk-emergency/20 text-risk-emergency"
  }.freeze

  METRIC_NAME_LABEL = {
    "precipitation_3h"  => "Precipitação (3h)",
    "precipitation_1h"  => "Precipitação (1h)",
    "precipitation_24h" => "Precipitação (24h)",
    "soil_moisture"     => "Umidade do solo",
    "temperature"       => "Temperatura",
    "humidity"          => "Umidade relativa"
  }.freeze

  SENSOR_TYPE_LABEL = {
    "pluviometer"     => "Pluviômetro",
    "weather_station" => "Meteorológica"
  }.freeze

  SENSOR_TYPE_BADGE_CLASSES = {
    "pluviometer"     => "bg-sensor-pluviometer/20 text-sensor-pluviometer",
    "weather_station" => "bg-sensor-weather/20 text-sensor-weather"
  }.freeze

  def severity_badge(severity)
    tag.span(
      SEVERITY_LABEL[severity.to_i],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SEVERITY_BADGE_CLASSES[severity.to_i]}"
    )
  end

  def risk_level_badge(level)
    tag.span(
      RISK_LEVEL_LABEL[level.to_s],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{RISK_LEVEL_BADGE_CLASSES[level.to_s]}"
    )
  end

  def sensor_type_badge(sensor_type)
    tag.span(
      SENSOR_TYPE_LABEL[sensor_type.to_s],
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-medium #{SENSOR_TYPE_BADGE_CLASSES[sensor_type.to_s]}"
    )
  end
end
