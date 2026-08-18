class AlarmMailer < ApplicationMailer
  def notification(alarm, user, severity, previous_severity: nil)
    @alarm             = alarm
    @user              = user
    @severity          = severity.to_i
    @previous_severity = previous_severity&.to_i
    @severity_label    = I18n.t("enums.severity.#{@severity}", default: "Alerta")
    @previous_severity_label = @previous_severity && I18n.t("enums.severity.#{@previous_severity}", default: nil)
    @alarm_url         = admin_alarm_url(alarm)
    @severity_color    = severity_color(@severity)
    @resolved          = @severity.zero?
    @direction         = direction

    mail(
      to: user.email_address,
      subject: subject_line
    )
  end

  private

  # nil previous_severity (the common case when this is called directly, e.g. every
  # existing test) means "unknown" — keeps today's plain subject/body, not a claimed
  # direction we don't actually know.
  def direction
    return :first if @previous_severity.blank?
    return :up if @severity > @previous_severity
    return :down if @severity < @previous_severity

    :same
  end

  def subject_line
    return "[NAILA] Resolvido — #{@alarm.name}" if @resolved

    case @direction
    when :up   then "[NAILA] Escalou para #{@severity_label} — #{@alarm.name}"
    when :down then "[NAILA] Reduziu para #{@severity_label} — #{@alarm.name}"
    else            "[NAILA] #{@severity_label} — #{@alarm.name}"
    end
  end

  def severity_color(severity)
    case severity
    when 4 then "#dc2626" # emergency — red
    when 3 then "#ea580c" # alerta máximo — orange
    when 2 then "#f59e0b" # alerta — amber
    when 0 then "#22c55e" # resolvido / vigilância — green (risk-normal)
    else        "#eab308" # atenção — yellow
    end
  end
end
