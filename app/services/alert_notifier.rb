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

  def self.notify_severity_change(alert, from_severity:, to_severity:)
    new(alert).notify_severity_change(from_severity: from_severity, to_severity: to_severity)
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

  def notify_severity_change(from_severity:, to_severity:)
    channels = if to_severity > from_severity
      old_channels = SEVERITY_CHANNELS.fetch(from_severity, %w[websocket])
      new_channels = SEVERITY_CHANNELS.fetch(to_severity, %w[websocket])
      ([ "websocket" ] + (new_channels - old_channels)).uniq
    else
      %w[websocket]
    end

    channels.each do |channel|
      notification = @alert.alert_notifications.create!(
        channel: channel,
        status: "pending",
        metadata: { type: "severity_change", from_severity: from_severity, to_severity: to_severity }
      )
      SendAlertNotificationJob.perform_later(notification.id)
    end
  end
end
