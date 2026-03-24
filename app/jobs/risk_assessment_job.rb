class RiskAssessmentJob < ApplicationJob
  queue_as :risk_assessment

  def perform(scope)
    zones = if scope == "all"
      RiskZone.active
    else
      RiskZone.where(id: scope)
    end

    zones.find_each do |zone|
      assessment = RiskEngine.assess(zone)
      alerts = AlertEvaluator.evaluate(assessment)
      alerts.each { |alert| AlertNotifier.dispatch(alert) }
    end
  end
end
