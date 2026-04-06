class MonitoringStationPolicy < ApplicationPolicy
  def create?  = user.can_manage?
  def update?  = user.can_manage?
  def destroy? = user.admin?
end
