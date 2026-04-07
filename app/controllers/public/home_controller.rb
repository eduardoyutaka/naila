module Public
  class HomeController < BaseController
    def index
      @city_risk_level = RiverBasin.at_risk.maximum(:current_risk_level) || 0
      @active_alarms_count = Alarm.in_alarm.count
      @basins_at_risk_count = RiverBasin.at_risk.count
      @highest_alarm = Alarm.in_alarm.order(current_severity: :desc).first
    end
  end
end
