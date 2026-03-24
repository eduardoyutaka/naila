class AlertNotifier
  SEVERITY_CHANNELS = {
    1 => %w[websocket],
    2 => %w[websocket sms push],
    3 => %w[websocket sms push email],
    4 => %w[websocket sms push email civil_defense]
  }.freeze

  def self.dispatch(alert)
    new(alert).dispatch
  end

  def initialize(alert)
    @alert = alert
  end

  def dispatch
    channels = SEVERITY_CHANNELS.fetch(@alert.severity, %w[websocket])

    channels.each do |channel|
      notification = @alert.alert_notifications.create!(
        channel: channel,
        status: "pending"
      )

      SendAlertNotificationJob.perform_later(notification.id)
    end
  end
end
