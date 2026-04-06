class AlarmEvaluationJob < ApplicationJob
  queue_as :alarm_evaluation

  def perform(scope = "all")
    case scope
    when "all"
      AlarmEvaluationEngine.evaluate_all
    else
      alarm = Alarm.find_by(id: scope)
      AlarmEvaluationEngine.evaluate_alarm(alarm) if alarm
    end
  end
end
