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
    assert_equal "[NAILA] Alerta Máximo — #{@alarm.name}", mail.subject
  end

  test "notification sends from the NAILA noreply address" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_match "noreply@nailariscos.com", mail.from.first
  end

  test "html body contains alarm name, severity label, state reason, and a link" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    body = mail.html_part.body.encoded

    assert_match @alarm.name, body
    assert_match "Alerta Máximo", body
    assert_match @alarm.state_reason, body
    assert_match %r{/admin/alarms/#{@alarm.id}}, body
  end

  test "text body contains alarm name, severity label, state reason, and a link" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    body = mail.text_part.body.encoded

    assert_match @alarm.name, body
    assert_match "Alerta Máximo", body
    assert_match @alarm.state_reason, body
    assert_match %r{/admin/alarms/#{@alarm.id}}, body
  end

  test "notification greets the user by name" do
    mail = AlarmMailer.notification(@alarm, @user, 3)
    assert_match @user.name, mail.html_part.body.encoded
    assert_match @user.name, mail.text_part.body.encoded
  end
end
