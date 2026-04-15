class NotificationRulePreview
  Result = Data.define(:rule_count, :email_recipient_count, :sms_recipient_count) do
    def fires_any?
      rule_count.positive?
    end
  end

  EMPTY = Result.new(rule_count: 0, email_recipient_count: 0, sms_recipient_count: 0)

  def self.for_alarm(alarm)
    severity = alarm.current_severity
    return EMPTY if severity.blank?

    rules = NotificationRule.enabled.triggered_by_severity(severity)
    return EMPTY if rules.empty?

    email_ids = rules.for_channel("email").flat_map { |r| r.resolved_recipients.pluck(:id) }.uniq
    sms_ids   = rules.for_channel("sms").flat_map   { |r| r.resolved_recipients.pluck(:id) }.uniq

    Result.new(
      rule_count: rules.count,
      email_recipient_count: email_ids.size,
      sms_recipient_count: sms_ids.size
    )
  end
end
