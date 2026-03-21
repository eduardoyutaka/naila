class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def create?  = user.admin?
  def update?  = user.admin?
  def destroy? = user.admin?
end
