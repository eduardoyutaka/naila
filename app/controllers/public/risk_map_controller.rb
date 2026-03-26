module Public
  class RiskMapController < BaseController
    def index
      @river_basins = RiverBasin.active
      @active_alerts = Alert.active.by_severity.limit(5)
    end
  end
end
