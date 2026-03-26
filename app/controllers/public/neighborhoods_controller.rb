module Public
  class NeighborhoodsController < BaseController
    def index
      @neighborhoods = Neighborhood.includes(:region)
                                   .order(current_risk_level: :desc, name: :asc)
    end

    def show
      @neighborhood = Neighborhood.find_by!(code: params[:code])
      @active_river_basins = RiverBasin.at_risk
      @active_alerts = @neighborhood.alerts.active.by_severity
    end
  end
end
