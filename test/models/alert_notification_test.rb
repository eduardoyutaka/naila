require "test_helper"

class AlertNotificationTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    notification = AlertNotification.new(
      alert: alerts(:active_high),
      channel: "push",
      status: "pending"
    )
    assert notification.valid?
  end

  test "invalid without channel" do
    notification = alert_notifications(:websocket_sent)
    notification.channel = nil
    assert_not notification.valid?
  end

  test "invalid without status" do
    notification = alert_notifications(:websocket_sent)
    notification.status = nil
    assert_not notification.valid?
  end

  test "channel must be a valid type" do
    notification = alert_notifications(:websocket_sent)
    notification.channel = "telegram"
    assert_not notification.valid?
  end

  # ── Scopes ──

  test "pending scope returns only pending notifications" do
    pending = AlertNotification.pending
    assert_includes pending, alert_notifications(:sms_pending)
    assert_not_includes pending, alert_notifications(:websocket_sent)
  end

  test "sent scope returns only sent notifications" do
    sent = AlertNotification.sent
    assert_includes sent, alert_notifications(:websocket_sent)
    assert_not_includes sent, alert_notifications(:sms_pending)
  end

  test "failed scope returns only failed notifications" do
    failed = AlertNotification.failed
    assert_includes failed, alert_notifications(:email_failed)
    assert_not_includes failed, alert_notifications(:websocket_sent)
  end

  # ── Associations ──

  test "belongs to alert" do
    assert_equal alerts(:active_high), alert_notifications(:websocket_sent).alert
  end
end
