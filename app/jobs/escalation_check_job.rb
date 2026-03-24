class EscalationCheckJob < ApplicationJob
  queue_as :default

  def perform
    EscalationEvaluator.check_escalations
  end
end
