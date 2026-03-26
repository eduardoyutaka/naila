class SendAlertNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(notification_id)
    notification = AlertNotification.find(notification_id)
    return if notification.status == "sent"

    case notification.channel
    when "websocket"
      deliver_websocket(notification)
    when "sms"
      deliver_sms(notification)
    when "push"
      deliver_push(notification)
    when "email"
      deliver_email(notification)
    when "civil_defense"
      deliver_civil_defense(notification)
    end

    notification.update!(status: "sent", sent_at: Time.current)
  rescue StandardError => e
    notification&.update!(status: "failed", failure_reason: e.message)
    Rails.logger.error("[SendAlertNotificationJob] Failed: #{e.message}")
  end

  private

  def deliver_websocket(notification)
    alert = notification.alert
    event_type = notification.metadata&.dig("type") || "new_alert"

    payload = {
      type: event_type,
      alert_id: alert.id,
      title: alert.title,
      severity: alert.severity,
      description: alert.description
    }

    if event_type == "severity_change"
      payload[:from_severity] = notification.metadata["from_severity"]
      payload[:to_severity] = notification.metadata["to_severity"]
    end

    ActionCable.server.broadcast("alerts", payload)
  end

  def deliver_sms(_notification)
    # TODO: implement Twilio SMS delivery
    Rails.logger.info("[SendAlertNotificationJob] SMS delivery placeholder")
  end

  def deliver_push(_notification)
    # TODO: implement web-push delivery
    Rails.logger.info("[SendAlertNotificationJob] Push delivery placeholder")
  end

  def deliver_email(_notification)
    # TODO: implement email delivery
    Rails.logger.info("[SendAlertNotificationJob] Email delivery placeholder")
  end

  def deliver_civil_defense(_notification)
    # TODO: implement civil defense notification
    Rails.logger.info("[SendAlertNotificationJob] Civil defense delivery placeholder")
  end
end
