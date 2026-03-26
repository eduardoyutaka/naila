require "test_helper"

class AlertNotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def create_alert(severity:)
    Alert.create!(
      title: "Alerta de teste",
      description: "Descrição do alerta de teste",
      severity: severity,
      alert_type: "automatic",
      status: "active",
      activated_at: Time.current
    )
  end

  test "severity 1 creates websocket notification only" do
    alert = create_alert(severity: 1)

    AlertNotifier.dispatch(alert)

    channels = alert.alert_notifications.pluck(:channel)
    assert_equal %w[websocket], channels
  end

  test "severity 2 creates websocket, sms, and push notifications" do
    alert = create_alert(severity: 2)

    AlertNotifier.dispatch(alert)

    channels = alert.alert_notifications.pluck(:channel).sort
    assert_equal %w[push sms websocket], channels
  end

  test "severity 3 creates websocket, sms, push, and email notifications" do
    alert = create_alert(severity: 3)

    AlertNotifier.dispatch(alert)

    channels = alert.alert_notifications.pluck(:channel).sort
    assert_equal %w[email push sms websocket], channels
    assert_not_includes channels, "civil_defense"
  end

  test "severity 4 creates all channels including civil_defense" do
    alert = create_alert(severity: 4)

    AlertNotifier.dispatch(alert)

    channels = alert.alert_notifications.pluck(:channel).sort
    assert_equal %w[civil_defense email push sms websocket], channels
  end

  test "notifications are created with pending status" do
    alert = create_alert(severity: 3)

    AlertNotifier.dispatch(alert)

    assert alert.alert_notifications.all? { |n| n.status == "pending" }
  end

  test "enqueues SendAlertNotificationJob for each notification" do
    alert = create_alert(severity: 3)

    AlertNotifier.dispatch(alert)

    assert_enqueued_jobs 4, only: SendAlertNotificationJob
  end

  # ── notify_severity_change ──

  test "escalation from sev 1 to 3 notifies newly added channels plus websocket" do
    alert = create_alert(severity: 3)

    AlertNotifier.notify_severity_change(alert, from_severity: 1, to_severity: 3)

    channels = alert.alert_notifications.pluck(:channel).sort
    assert_equal %w[email push sms websocket], channels
  end

  test "escalation from sev 2 to 4 notifies only newly added channels plus websocket" do
    alert = create_alert(severity: 4)

    AlertNotifier.notify_severity_change(alert, from_severity: 2, to_severity: 4)

    channels = alert.alert_notifications.pluck(:channel).sort
    # sms and push already existed at sev 2; email and civil_defense are new
    assert_equal %w[civil_defense email websocket], channels
  end

  test "de-escalation notifies websocket only" do
    alert = create_alert(severity: 1)

    AlertNotifier.notify_severity_change(alert, from_severity: 3, to_severity: 1)

    channels = alert.alert_notifications.pluck(:channel)
    assert_equal %w[websocket], channels
  end

  test "severity change notifications record metadata with from/to severity" do
    alert = create_alert(severity: 2)

    AlertNotifier.notify_severity_change(alert, from_severity: 1, to_severity: 2)

    notification = alert.alert_notifications.find_by(channel: "websocket")
    assert_equal "severity_change", notification.metadata["type"]
    assert_equal 1, notification.metadata["from_severity"]
    assert_equal 2, notification.metadata["to_severity"]
  end

  test "severity change enqueues SendAlertNotificationJob for each notification" do
    alert = create_alert(severity: 3)

    AlertNotifier.notify_severity_change(alert, from_severity: 1, to_severity: 3)

    assert_enqueued_jobs 4, only: SendAlertNotificationJob
  end
end
