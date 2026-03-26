module Admin
  class AlertThresholdsController < BaseController
    before_action :set_alert_threshold, only: [:show, :edit, :update, :destroy]

    def index
      @alert_thresholds = AlertThreshold.includes(:river_basin, :river)
                                        .order(parameter: :asc, severity: :asc)
    end

    def show
      @alerts = @alert_threshold.alerts.order(created_at: :desc).limit(10)
    end

    def new
      @alert_threshold = AlertThreshold.new(active: true, comparison: "gte", cooldown_minutes: 60)
    end

    def create
      @alert_threshold = AlertThreshold.new(alert_threshold_params)
      authorize @alert_threshold

      if @alert_threshold.save
        redirect_to admin_alert_threshold_path(@alert_threshold), notice: "Limiar criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @alert_threshold
      if @alert_threshold.update(alert_threshold_params)
        redirect_to admin_alert_threshold_path(@alert_threshold), notice: "Limiar atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @alert_threshold
      @alert_threshold.destroy!
      redirect_to admin_alert_thresholds_path, notice: "Limiar excluído com sucesso."
    end

    private

    def set_alert_threshold
      @alert_threshold = AlertThreshold.find(params[:id])
    end

    def alert_threshold_params
      params.require(:alert_threshold).permit(
        :parameter, :threshold_type, :severity, :value, :unit,
        :comparison, :river_basin_id, :river_id, :active, :cooldown_minutes
      )
    end
  end
end
