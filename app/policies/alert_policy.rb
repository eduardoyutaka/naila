class AlertPolicy < ApplicationPolicy
  def acknowledge?
    true
  end

  def resolve?
    user.can_manage_alerts?
  end
end
