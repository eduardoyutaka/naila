module Admin
  class AlarmsController < BaseController
    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_alarm, only: [ :show, :edit, :update, :destroy, :history ]

    def index
      @alarms = policy_scope(Alarm).includes(:river_basin, :river)
                                   .order(enabled: :desc, name: :asc)
    end

    def show
      authorize @alarm
      @alarm_actions = @alarm.alarm_actions.order(trigger_state: :asc)
      @state_histories = @alarm.alarm_state_histories.order(evaluated_at: :desc).limit(20)
      @child_alarms = @alarm.composite? ? @alarm.child_alarms.includes(:river_basin, :river) : []
    end

    def new
      @alarm = Alarm.new(alarm_type: "metric", enabled: true,
                         evaluation_periods: 1, datapoints_to_alarm: 1,
                         missing_data_treatment: "missing")
      authorize @alarm
      @alarm.alarm_thresholds.build(severity: 1)
    end

    def create
      @alarm = Alarm.new(alarm_params)
      authorize @alarm

      if @alarm.save
        redirect_to admin_alarm_path(@alarm), notice: "Alarme criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @alarm
    end

    def update
      authorize @alarm
      if @alarm.update(alarm_params)
        redirect_to admin_alarm_path(@alarm), notice: "Alarme atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @alarm
      @alarm.destroy!
      redirect_to admin_alarms_path, notice: "Alarme removido com sucesso."
    end

    def history
      authorize @alarm
      @state_histories = @alarm.alarm_state_histories.order(evaluated_at: :desc)
    end


    private

    def set_alarm
      @alarm = Alarm.find(params[:id])
    end

    def alarm_params
      params.require(:alarm).permit(
        :name, :description, :alarm_type, :enabled,
        :river_basin_id, :river_id,
        :metric_name, :statistic, :period_seconds, :evaluation_periods,
        :datapoints_to_alarm, :missing_data_treatment,
        :anomaly_band_width, :anomaly_baseline_id,
        :composite_rule, :suppress_child_actions,
        alarm_thresholds_attributes: [ :id, :severity, :comparison_operator, :threshold_value, :unit, :_destroy ]
      )
    end
  end
end
