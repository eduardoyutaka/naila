class AlarmSmsRenderer
  SEVERITY_LABELS = {
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alerta Máximo",
    4 => "Emergência"
  }.freeze

  MAX_BODY_LENGTH = 160
  MAX_NAME_LENGTH = 80

  def self.render(alarm, severity)
    new(alarm, severity).render
  end

  def initialize(alarm, severity)
    @alarm = alarm
    @severity = severity.to_i
  end

  def render
    label = SEVERITY_LABELS.fetch(@severity, "Alerta")
    name  = @alarm.name.to_s.truncate(MAX_NAME_LENGTH, omission: "…")
    body  = "[NAILA] #{label}: #{name}. Acesse o painel."
    body.length > MAX_BODY_LENGTH ? body.truncate(MAX_BODY_LENGTH, omission: "…") : body
  end
end
