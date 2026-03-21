module Admin
  class RiskZonesController < BaseController
    before_action :set_risk_zone, only: [:show, :edit, :update, :destroy]

    def index
      @risk_zones = RiskZone.includes(:neighborhood, :drainage_basin)
                            .order(current_risk_level: :desc, name: :asc)
    end

    def show
      @recent_assessments = @risk_zone.risk_assessments.order(assessed_at: :desc).limit(10)
      @active_alerts = @risk_zone.alerts.active.by_severity
    end

    def new
      @risk_zone = RiskZone.new
    end

    def create
      @risk_zone = RiskZone.new(risk_zone_params)
      authorize @risk_zone

      if @risk_zone.save
        redirect_to admin_risk_zone_path(@risk_zone), notice: "Zona de risco criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @risk_zone
      if @risk_zone.update(risk_zone_params)
        redirect_to admin_risk_zone_path(@risk_zone), notice: "Zona de risco atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @risk_zone
      @risk_zone.destroy!
      redirect_to admin_risk_zones_path, notice: "Zona de risco removida."
    end

    private

    def set_risk_zone
      @risk_zone = RiskZone.find(params[:id])
    end

    def risk_zone_params
      params.require(:risk_zone).permit(
        :name, :description, :zone_type, :geometry,
        :neighborhood_id, :drainage_basin_id, :active
      )
    end
  end
end
