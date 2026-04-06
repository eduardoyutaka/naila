class RiskAssessmentJob < ApplicationJob
  queue_as :risk_assessment

  def perform(scope)
    basins = if scope == "all"
      RiverBasin.active
    else
      RiverBasin.where(id: scope)
    end

    basins.find_each do |basin|
      RiskEngine.assess(basin)
    end

    AlarmEvaluationJob.perform_later("all")
  end
end
