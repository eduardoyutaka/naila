require "test_helper"

class AlarmMailerTest < ActionMailer::TestCase
  setup do
    @alarm = alarms(:flood_alert_belem)
    @user  = users(:admin)
  end

  test "notification is delivered to the user's email address" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_equal [ @user.email_address ], mail.to
  end

  test "notification subject includes severity label and alarm name" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_equal "[NAILA] Alarme — #{@alarm.name}", mail.subject
  end

  test "notification sends from the configured alerts address" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_match "alertas@nailariscos.com", mail.from.first
  end

  test "html body contains alarm name, severity label, state reason, and a link" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    body = mail.html_part.body.encoded

    assert_match @alarm.name, body
    assert_match "Alarme", body
    assert_match @alarm.state_reason, body
    assert_match %r{/admin/alarms/#{@alarm.id}}, body
  end

  test "text body contains alarm name, severity label, state reason, and a link" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    body = mail.text_part.body.encoded

    assert_match @alarm.name, body
    assert_match "Alarme", body
    assert_match @alarm.state_reason, body
    assert_match %r{/admin/alarms/#{@alarm.id}}, body
  end

  test "notification greets the user by name" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_match @user.name, mail.html_part.body.encoded
    assert_match @user.name, mail.text_part.body.encoded
  end

  test "subject escalation-frames when previous_severity is lower" do
    mail = AlarmMailer.notification(@alarm, @user, 3, previous_severity: 2)
    assert_equal "[NAILA] Escalou para Alarme — #{@alarm.name}", mail.subject
  end

  test "subject de-escalation-frames when previous_severity is higher" do
    mail = AlarmMailer.notification(@alarm, @user, 2, previous_severity: 3)
    assert_equal "[NAILA] Reduziu para Alerta — #{@alarm.name}", mail.subject
  end

  test "subject stays plain when previous_severity is unknown" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_equal "[NAILA] Alarme — #{@alarm.name}", mail.subject
  end

  test "subject reads Resolvido for severity 0" do
    mail = AlarmMailer.notification(@alarm, @user, 0, previous_severity: 3)
    assert_equal "[NAILA] Resolvido — #{@alarm.name}", mail.subject
  end

  test "html and text bodies mention escalation direction" do
    mail = AlarmMailer.notification(@alarm, @user, 3, previous_severity: 2)
    assert_match "escalou", mail.html_part.body.encoded
    assert_match "escalou", mail.text_part.body.encoded
  end

  test "html and text bodies mention resolution" do
    mail = AlarmMailer.notification(@alarm, @user, 0, previous_severity: 3)
    assert_match "Vigilância", mail.html_part.body.encoded
    assert_match "Vigilância", mail.text_part.body.encoded
  end
end
