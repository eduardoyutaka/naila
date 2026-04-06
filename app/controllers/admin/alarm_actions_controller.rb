module Admin
  class AlarmActionsController < BaseController
    before_action :set_alarm
    before_action :set_alarm_action, only: [ :edit, :update, :destroy ]

    def new
      @alarm_action = @alarm.alarm_actions.new(enabled: true)
    end

    def create
      @alarm_action = @alarm.alarm_actions.new(alarm_action_params)
      authorize @alarm_action

      if @alarm_action.save
        redirect_to admin_alarm_path(@alarm), notice: "Ação criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @alarm_action
      if @alarm_action.update(alarm_action_params)
        redirect_to admin_alarm_path(@alarm), notice: "Ação atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @alarm_action
      @alarm_action.destroy!
      redirect_to admin_alarm_path(@alarm), notice: "Ação removida com sucesso."
    end

    private

    def set_alarm
      @alarm = Alarm.find(params[:alarm_id])
    end

    def set_alarm_action
      @alarm_action = @alarm.alarm_actions.find(params[:id])
    end

    def alarm_action_params
      params.require(:alarm_action).permit(:trigger_state, :action_type, :enabled, configuration: {})
    end
  end
end
