module Admin
  module Alarms
    class AcknowledgmentsController < Admin::BaseController
      before_action :set_alarm

      def update
        authorize @alarm

        if params[:acknowledged] == "true"
          @alarm.acknowledge!(current_user)
          notice = "Alarme reconhecido."
        else
          @alarm.unacknowledge!
          notice = "Reconhecimento removido."
        end

        redirect_to admin_alarm_path(@alarm), notice: notice
      end

      private

      def set_alarm
        @alarm = Alarm.find(params[:alarm_id])
      end
    end
  end
end
