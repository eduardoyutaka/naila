class AlarmPolicy < ApplicationPolicy
  def history?
    true
  end

  def enable?
    user.can_manage_alerts?
  end

  def disable?
    user.can_manage_alerts?
  end
end
