module Admin
  class AlertsController < BaseController
    before_action :set_alert, only: [ :show, :acknowledge, :resolve ]

    def index
      @alerts = Alert.includes(:river_basin, :neighborhood, :river)
                     .order(severity: :desc, created_at: :desc)
    end

    def show
      @notifications = @alert.alert_notifications.order(created_at: :desc)
    end

    def new
      @alert = Alert.new(alert_type: "manual")
    end

    def create
      @alert = Alert.new(alert_params)
      @alert.alert_type = "manual"
      @alert.status = "active"
      @alert.created_by = current_user
      authorize @alert, :create?

      if @alert.save
        redirect_to admin_alert_path(@alert), notice: "Alerta criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def acknowledge
      authorize @alert
      @alert.acknowledge!(current_user)
      redirect_to admin_alert_path(@alert), notice: "Alerta reconhecido."
    end

    def resolve
      authorize @alert
      @alert.resolve!(current_user)
      redirect_to admin_alert_path(@alert), notice: "Alerta resolvido."
    end

    private

    def set_alert
      @alert = Alert.find(params[:id])
    end

    def alert_params
      params.require(:alert).permit(
        :title, :description, :instructions, :severity,
        :river_basin_id, :neighborhood_id, :river_id
      )
    end
  end
end
