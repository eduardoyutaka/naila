class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = true
  def show?    = true
  def create?  = user.can_manage_alerts?
  def update?  = user.can_manage_alerts?
  def destroy? = user.admin?
end
