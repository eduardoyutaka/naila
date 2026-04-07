module Admin
  module Alarms
    class StatusesController < Admin::BaseController
      before_action :set_alarm

      def update
        authorize @alarm

        @alarm.update!(enabled: params[:enabled] == "true")
        status_text = @alarm.enabled? ? "ativado" : "desativado"
        redirect_to admin_alarm_path(@alarm), notice: "Alarme #{status_text}."
      end

      private

      def set_alarm
        @alarm = Alarm.find(params[:alarm_id])
      end
    end
  end
end
