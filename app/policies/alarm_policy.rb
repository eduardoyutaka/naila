class AlarmPolicy < ApplicationPolicy
  def history?
    true
  end

  def metric_history?
    true
  end
end
