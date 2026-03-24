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
end
