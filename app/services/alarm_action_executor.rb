class AlarmActionExecutor
  def self.execute(alarm, new_state)
    new(alarm).execute(new_state)
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def execute(new_state)
    return if suppressed_by_parent?

    current_sev = @alarm.current_severity
    actions = @alarm.alarm_actions.enabled.for_state(new_state)
    actions.each do |action|
      next if action.min_severity.present? && (current_sev.nil? || current_sev < action.min_severity)

      case action.action_type
      when "notification"
        execute_notification(action, new_state)
      when "webhook"
        execute_webhook(action, new_state)
      end
    end
  end

  private

  def execute_notification(action, new_state)
    config = action.configuration
    config = JSON.parse(config) if config.is_a?(String)
    channels = config["channels"] || %w[websocket]

    payload = {
      event_type: "alarm_state_change",
      alarm_id: @alarm.id,
      alarm_name: @alarm.name,
      state: new_state,
      current_severity: @alarm.current_severity,
      river_basin_id: @alarm.river_basin_id,
      reason: @alarm.state_reason
    }

    channels.each do |channel|
      case channel
      when "websocket"
        ActionCable.server.broadcast("alarms", payload)
      when "sms", "push", "email", "civil_defense"
        raise NotImplementedError, "Canal '#{channel}' ainda não está implementado."
      end
    end
  end

  def execute_webhook(action, new_state)
    config = action.configuration
    config = JSON.parse(config) if config.is_a?(String)

    SendWebhookJob.perform_later(
      config["url"],
      config["method"] || "POST",
      build_webhook_payload(new_state),
      config["headers"] || {}
    )
  end

  def build_webhook_payload(new_state)
    {
      alarm_id: @alarm.id,
      alarm_name: @alarm.name,
      alarm_type: @alarm.alarm_type,
      new_state: new_state,
      current_severity: @alarm.current_severity,
      reason: @alarm.state_reason,
      timestamp: Time.current.iso8601
    }
  end

  def suppressed_by_parent?
    @alarm.parent_composite_links
          .joins("INNER JOIN alarms ON alarms.id = composite_alarm_children.composite_alarm_id")
          .where(alarms: { suppress_child_actions: true })
          .exists?
  end
end
