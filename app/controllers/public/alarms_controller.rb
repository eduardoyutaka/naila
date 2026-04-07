module Public
  class AlarmsController < BaseController
    def index
      @active_alarms = Alarm.in_alarm.includes(:river_basin, :river).order(current_severity: :desc)
      @recently_resolved = Alarm.where(state: "ok").order(state_changed_at: :desc).limit(10)
    end
  end
end
