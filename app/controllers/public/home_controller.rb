module Public
  class HomeController < BaseController
    def index
      @city_risk_level = RiskZone.at_risk.maximum(:current_risk_level) || 0
      @active_alerts_count = Alert.active.count
      @zones_at_risk_count = RiskZone.at_risk.count
      @highest_alert = Alert.active.by_severity.first
    end
  end
end
