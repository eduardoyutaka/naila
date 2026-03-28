module Admin
  class AlertThresholdsController < BaseController
    before_action :set_alert_threshold, only: [:edit, :update, :destroy]
    before_action :set_return_alert, only: [:new, :create, :edit, :update, :destroy]

    def new
      @alert_threshold = AlertThreshold.new(
        active: true,
        comparison: "gte",
        cooldown_minutes: 60,
        river_basin_id: params[:river_basin_id],
        river_id: params[:river_id]
      )
    end

    def create
      @alert_threshold = AlertThreshold.new(alert_threshold_params)
      authorize @alert_threshold

      if @alert_threshold.save
        redirect_to return_path, notice: "Limiar criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @alert_threshold
      if @alert_threshold.update(alert_threshold_params)
        redirect_to return_path, notice: "Limiar atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @alert_threshold
      @alert_threshold.destroy!
      redirect_to return_path, notice: "Limiar excluído com sucesso."
    end

    private

    def set_alert_threshold
      @alert_threshold = AlertThreshold.find(params[:id])
    end

    def set_return_alert
      @return_alert = Alert.find_by(id: params[:alert_id])
    end

    def return_path
      @return_alert ? admin_alert_path(@return_alert) : admin_alerts_path
    end

    def alert_threshold_params
      params.require(:alert_threshold).permit(
        :parameter, :threshold_type, :severity, :value, :unit,
        :comparison, :river_basin_id, :river_id, :active, :cooldown_minutes
      )
    end
  end
end
