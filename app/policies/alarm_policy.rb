class AlarmPolicy < ApplicationPolicy
  def history?
    true
  end

  def enable?
    user.can_manage?
  end

  def disable?
    user.can_manage?
  end
end
