module Public
  class AlertsController < BaseController
    def index
      @active_alerts = Alert.active.includes(:risk_zone, :neighborhood).by_severity
      @recent_resolved = Alert.where(status: "resolved")
                              .order(resolved_at: :desc)
                              .limit(10)
    end
  end
end
