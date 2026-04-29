class AlarmActionExecutor
  def self.execute(alarm, new_state)
    new(alarm).execute(new_state)
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def execute(new_state)
    current_sev = @alarm.current_severity
    actions = @alarm.alarm_actions.enabled.for_state(new_state)
    actions.each do |action|
      next if action.min_severity.present? && (current_sev.nil? || current_sev < action.min_severity)

      execute_notification(action, new_state) if action.action_type == "notification"
    end
  end

  private

  # Notification actions broadcast the state transition over ActionCable
  # on every state change. Email and SMS dispatch is governed globally by
  # NotificationRule records and only fires on transitions to "alarm".
  def execute_notification(action, new_state)
    ActionCable.server.broadcast("alarms", build_payload(new_state))

    return unless new_state == "alarm"

    severity = @alarm.current_severity
    return if severity.blank?

    rules = NotificationRule.enabled.triggered_by_severity(severity)

    rules.for_channel("email").flat_map { |r| r.resolved_recipients.pluck(:id) }.uniq.each do |user_id|
      SendAlarmEmailJob.perform_later(@alarm.id, user_id, severity)
    end

    rules.for_channel("sms").flat_map { |r| r.resolved_recipients.pluck(:id) }.uniq.each do |user_id|
      SendAlarmSmsJob.perform_later(@alarm.id, user_id, severity)
    end
  end

  def build_payload(new_state)
    {
      event_type: "alarm_state_change",
      alarm_id: @alarm.id,
      alarm_name: @alarm.name,
      state: new_state,
      current_severity: @alarm.current_severity,
      river_basin_id: @alarm.river_basin_id,
      reason: @alarm.state_reason
    }
  end
end
