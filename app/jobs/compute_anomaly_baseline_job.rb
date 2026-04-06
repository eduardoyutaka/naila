class ComputeAnomalyBaselineJob < ApplicationJob
  queue_as :default

  def perform
    Alarm.enabled.anomaly_alarms.find_each do |alarm|
      AnomalyBaselineComputer.compute(
        metric_name: alarm.metric_name,
        river_basin: alarm.river_basin,
        river: alarm.river,
        training_window_days: alarm.anomaly_baseline&.training_window_days || 90
      )
    end
  end
end
