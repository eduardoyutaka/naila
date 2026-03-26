class SensorPolicy < ApplicationPolicy
  def create?  = user.can_manage_alerts?
  def update?  = user.can_manage_alerts?
  def destroy? = user.admin?
end
