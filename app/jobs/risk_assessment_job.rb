class RiskAssessmentJob < ApplicationJob
  queue_as :risk_assessment

  def perform(scope)
    # Will be implemented in Step 19
  end
end
