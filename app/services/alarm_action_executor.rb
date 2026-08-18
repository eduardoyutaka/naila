class AlarmActionExecutor
  def self.execute(alarm, new_state, previous_severity: nil, previous_peak: nil)
    new(alarm).execute(new_state, previous_severity: previous_severity, previous_peak: previous_peak)
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def execute(new_state, previous_severity: nil, previous_peak: nil)
    current_sev = @alarm.current_severity
    actions = @alarm.alarm_actions.for_state(new_state).select do |a|
      a.min_severity.blank? || (current_sev.present? && current_sev >= a.min_severity)
    end

    actions.each do |a|
      ActionCable.server.broadcast("alarms", build_payload(new_state)) if a.action_type == "notification"
    end

    return unless actions.any? { |a| a.action_type == "notification" }
    return unless notify_recipients?(new_state, current_sev, previous_peak)

    dispatch_recipient_notifications(new_state, current_sev, previous_severity, previous_peak)
  end

  private

  # A "connected" fetch or a broadcast happening isn't the same as someone actually
  # needing to hear about it. Recipients are only paged on a genuinely new development:
  # climbing past the highest severity reached so far this episode (never on a repeat or
  # a drop — see episode_peak_severity), or the episode fully resolving back to "ok" after
  # someone was actually notified during it.
  def notify_recipients?(new_state, current_sev, previous_peak)
    case new_state
    when "alarm" then current_sev.present? && current_sev > previous_peak.to_i
    when "ok"    then previous_peak.present?
    else false
    end
  end

  def dispatch_recipient_notifications(new_state, current_sev, previous_severity, previous_peak)
    if new_state == "ok"
      rules = NotificationRule.enabled.triggered_by_severity(previous_peak)
      notify_severity = 0
      notify_previous = previous_peak
    else
      rules = NotificationRule.enabled.triggered_by_severity(current_sev)
      notify_severity = current_sev
      notify_previous = previous_severity
    end

    rules.for_channel("email").flat_map { |r| r.resolved_recipients.pluck(:id) }.uniq.each do |user_id|
      SendAlarmEmailJob.perform_later(@alarm.id, user_id, notify_severity, previous_severity: notify_previous)
    end

    rules.for_channel("sms").flat_map { |r| r.resolved_recipients.pluck(:id) }.uniq.each do |user_id|
      SendAlarmSmsJob.perform_later(@alarm.id, user_id, notify_severity, previous_severity: notify_previous)
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
