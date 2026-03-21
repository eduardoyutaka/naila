module Public
  class SafetyController < BaseController
    def index
      @evacuation_routes = EvacuationRoute.includes(:risk_zone).where(active: true)
    end
  end
end
