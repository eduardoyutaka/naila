class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = true
  def show?    = true
  def new?     = create?
  def edit?    = update?
  def create?  = user.can_manage?
  def update?  = user.can_manage?
  def destroy? = user.admin?

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :user, :scope
  end
end
