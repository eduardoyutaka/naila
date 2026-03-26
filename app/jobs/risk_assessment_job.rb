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
      results = AlertEvaluator.evaluate(assessment)

      results.each do |result|
        case result[:action]
        when :created
          AlertNotifier.dispatch(result[:alert])
        when :updated
          AlertNotifier.notify_severity_change(
            result[:alert],
            from_severity: result[:from_severity],
            to_severity: result[:alert].severity
          )
        when :resolved
          AlertNotifier.notify_severity_change(
            result[:alert],
            from_severity: result[:from_severity],
            to_severity: 0
          )
        end
      end
    end
  end
end
