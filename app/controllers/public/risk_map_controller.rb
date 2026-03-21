module Public
  class RiskMapController < BaseController
    def index
      @risk_zones = RiskZone.active.includes(:neighborhood)
      @active_alerts = Alert.active.by_severity.limit(5)
    end
  end
end
