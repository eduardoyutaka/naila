module Public
  class SafetyController < BaseController
    def index
      @evacuation_routes = EvacuationRoute.includes(:river_basin).where(active: true)
    end
  end
end
