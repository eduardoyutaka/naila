class AlarmSmsRenderer
  MAX_BODY_LENGTH = 160
  MAX_NAME_LENGTH = 80

  def self.render(alarm, severity, previous_severity: nil)
    new(alarm, severity, previous_severity: previous_severity).render
  end

  def initialize(alarm, severity, previous_severity: nil)
    @alarm = alarm
    @severity = severity.to_i
    @previous_severity = previous_severity&.to_i
  end

  def render
    name = @alarm.name.to_s.truncate(MAX_NAME_LENGTH, omission: "…")
    body = "[NAILA] #{body_prefix}: #{name}#{body_suffix}"
    body.length > MAX_BODY_LENGTH ? body.truncate(MAX_BODY_LENGTH, omission: "…") : body
  end

  private

  def label
    I18n.t("enums.severity.#{@severity}", default: "Alerta")
  end

  def body_prefix
    return "Resolvido" if @severity.zero?
    return "Subiu para #{label}" if @previous_severity.present? && @severity > @previous_severity
    return "Desceu para #{label}" if @previous_severity.present? && @severity < @previous_severity

    label
  end

  def body_suffix
    @severity.zero? ? ". Voltou à Vigilância." : ". Acesse o painel."
  end
end
