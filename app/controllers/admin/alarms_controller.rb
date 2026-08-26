module Admin
  class AlarmsController < BaseController
    include Filterable

    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_alarm, only: [ :show, :edit, :update, :destroy, :history ]

    def index
      base_scope = policy_scope(Alarm).includes(:river_basin, :river)
      @summary_counts = alarm_summary_counts(base_scope)

      q = filter_params(:search, :state, :enabled)
      scope = base_scope
      scope = scope.search_by_name(q[:search]) if q[:search].present?
      scope = scope.by_state(q[:state])        if q[:state].present?
      scope = scope.by_enabled(q[:enabled])    if q[:enabled].present?

      @pagy, @alarms = pagy(scope.order(enabled: :desc, name: :asc))
    end

    def show
      authorize @alarm
      @alarm_actions = @alarm.alarm_actions.order(trigger_state: :asc)
      @state_histories = @alarm.alarm_state_histories.order(evaluated_at: :desc).limit(20)
      @notification_preview = NotificationRulePreview.for_alarm(@alarm)
      @child_alarms = []
      assign_chart_data
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

    CHART_WINDOW = 48.hours
    MIN_CHART_PERIODS = 12
    MAX_CHART_PERIODS = 96

    def assign_chart_data
      @chart_thresholds = @alarm.alarm_thresholds.order(:severity).map { |t|
        { value: t.threshold_value, severity: t.severity, label: I18n.t("enums.severity.#{t.severity}") }
      }
      @chart_unit = @alarm.alarm_thresholds.first&.unit
      @last_known_reading_at = last_known_reading_at

      if @alarm.river_basin.blank? || @alarm.alarm_thresholds.empty?
        @chart_readings = []
        return
      end

      periods = (CHART_WINDOW / @alarm.period_seconds.seconds).to_i.clamp(MIN_CHART_PERIODS, MAX_CHART_PERIODS)
      series = MetricDataCollector.history_series(alarm: @alarm, periods: periods)
      @chart_readings = series.map { |pt| [ pt[:period_end].iso8601, pt[:value] ] }
    end

    # Mirrors the sensors MetricDataCollector#collect_precipitation actually reads from
    # (radius-based Sensor.nearby_pluviometers, not the basin's "designated" 1:1
    # monitoring_station, which can be a different, currently-silent station).
    def last_known_reading_at
      return nil unless @alarm.metric_name == "precipitation" && @alarm.river_basin.present?

      SensorReading.where(sensor_id: Sensor.nearby_pluviometers(@alarm.river_basin))
                   .by_type("precipitation")
                   .maximum(:recorded_at)
    end

    def alarm_summary_counts(scope)
      {
        total: scope.count,
        enabled: scope.enabled.count,
        alarm: scope.in_alarm.count,
        insufficient: scope.by_state("insufficient_data").count
      }
    end

    def alarm_params
      params.require(:alarm).permit(
        :name, :description, :alarm_type, :enabled,
        :river_basin_id, :river_id,
        :metric_name, :statistic, :period_seconds, :evaluation_periods,
        :datapoints_to_alarm, :missing_data_treatment,
        alarm_thresholds_attributes: [ :id, :severity, :comparison_operator, :threshold_value, :unit, :_destroy ]
      )
    end
  end
end
