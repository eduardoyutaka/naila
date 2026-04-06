class AlarmActionExecutor
  ALARM_STATE_TITLES = {
    "alarm" => "Alarme ativado",
    "ok" => "Alarme normalizado",
    "insufficient_data" => "Dados insuficientes"
  }.freeze

  def self.execute(alarm, new_state)
    new(alarm).execute(new_state)
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def execute(new_state)
    return if suppressed_by_parent?

    actions = @alarm.alarm_actions.enabled.for_state(new_state)
    actions.each do |action|
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

    alert = create_alert(new_state)

    channels.each do |channel|
      notification = alert.alert_notifications.create!(
        channel: channel,
        status: "pending",
        metadata: { alarm_id: @alarm.id, alarm_state: new_state }
      )
      SendAlertNotificationJob.perform_later(notification.id)
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

  def create_alert(new_state)
    title = "#{ALARM_STATE_TITLES[new_state]}: #{@alarm.name}"

    @alarm.alerts.create!(
      title: title,
      description: @alarm.state_reason || @alarm.description || title,
      severity: @alarm.severity,
      alert_type: "automatic",
      status: "active",
      activated_at: Time.current,
      alarm_state: new_state,
      river_basin: @alarm.river_basin,
      river: @alarm.river,
      affected_area: @alarm.river_basin&.geometry,
      trigger_data: {
        alarm_id: @alarm.id,
        alarm_name: @alarm.name,
        alarm_type: @alarm.alarm_type,
        alarm_state: new_state,
        severity: @alarm.severity,
        last_datapoints: @alarm.last_datapoints
      }
    )
  end

  def build_webhook_payload(new_state)
    {
      alarm_id: @alarm.id,
      alarm_name: @alarm.name,
      alarm_type: @alarm.alarm_type,
      new_state: new_state,
      severity: @alarm.severity,
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
