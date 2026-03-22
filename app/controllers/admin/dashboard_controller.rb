module Admin
  class DashboardController < BaseController
    def index
      @risk_zones = RiskZone.active.includes(:neighborhood)
      @active_alerts = Alert.active.by_severity.limit(10)
      @recent_readings = SensorReading.recent.limit(10)
      @sensors_online = SensorStation.online.count
      @zones_at_risk = RiskZone.at_risk.count
      @sensor_stations = SensorStation.where.not(location: nil).includes(:neighborhood, :river)
    end
  end
end
