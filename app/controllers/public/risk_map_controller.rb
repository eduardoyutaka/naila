module Public
  class RiskMapController < BaseController
    def index
      @river_basins = RiverBasin.active
      @active_alarms = Alarm.in_alarm.order(current_severity: :desc).limit(5)
    end
  end
end
