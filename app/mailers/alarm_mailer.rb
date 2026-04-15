class AlarmMailer < ApplicationMailer
  SEVERITY_LABELS = {
    1 => "Atenção",
    2 => "Alerta",
    3 => "Alerta Máximo",
    4 => "Emergência"
  }.freeze

  def notification(alarm, user, severity)
    @alarm           = alarm
    @user            = user
    @severity        = severity.to_i
    @severity_label  = SEVERITY_LABELS.fetch(@severity, "Alerta")
    @alarm_url       = admin_alarm_url(alarm)
    @severity_color  = severity_color(@severity)

    mail(
      to: user.email_address,
      subject: "[NAILA] #{@severity_label} — #{alarm.name}"
    )
  end

  private

  def severity_color(severity)
    case severity
    when 4 then "#dc2626" # emergency — red
    when 3 then "#ea580c" # alerta máximo — orange
    when 2 then "#f59e0b" # alerta — amber
    else        "#eab308" # atenção — yellow
    end
  end
end
