class EscalationEvaluator
  def self.check_escalations
    new.check_escalations
  end

  def check_escalations
    EscalationRule.where(active: true).find_each do |rule|
      eligible_alerts(rule).each do |alert|
        escalate(alert, rule)
      end
    end
  end

  private

  def eligible_alerts(rule)
    Alert.where(status: "active", acknowledged_at: nil, severity: rule.from_severity)
         .where("activated_at <= ?", rule.escalation_after_minutes.minutes.ago)
  end

  def escalate(alert, rule)
    alert.update!(severity: rule.to_severity)

    notification = alert.alert_notifications.create!(
      channel: "websocket",
      status: "pending",
      metadata: { escalation_rule_id: rule.id, from_severity: rule.from_severity, to_severity: rule.to_severity }
    )

    SendAlertNotificationJob.perform_later(notification.id)

    Rails.logger.info(
      "[EscalationEvaluator] Alert ##{alert.id} escalated from severity #{rule.from_severity} to #{rule.to_severity}"
    )
  end
end
