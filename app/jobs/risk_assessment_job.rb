class RiskAssessmentJob < ApplicationJob
  queue_as :risk_assessment

  def perform(scope)
    basins = if scope == "all"
      RiverBasin.active
    else
      RiverBasin.where(id: scope)
    end

    basins.find_each do |basin|
      assessment = RiskEngine.assess(basin)
      alerts = AlertEvaluator.evaluate(assessment)
      alerts.each { |alert| AlertNotifier.dispatch(alert) }
    end
  end
end
