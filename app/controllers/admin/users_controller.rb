module Admin
  class UsersController < BaseController
    include Filterable

    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_user, only: [:edit, :update, :destroy]
    before_action -> { authorize User }, only: [:index, :new, :create]
    before_action -> { authorize @user }, only: [:edit, :update, :destroy]

    def index
      base_scope = policy_scope(User).includes(:sessions)
      @summary_counts = user_summary_counts(base_scope)

      q = filter_params(:search, :role, :active)
      scope = base_scope
      scope = scope.search_by_name(q[:search]) if q[:search].present?
      scope = scope.by_role(q[:role])           if q[:role].present?
      scope = scope.by_active(q[:active])       if q[:active].present?

      @pagy, @users = pagy(scope.order(:name))
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: "Usuário criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = user_params
      update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

      if @user.update(update_params)
        redirect_to admin_users_path, notice: "Usuário atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Você não pode remover seu próprio usuário."
        return
      end

      @user.destroy!
      redirect_to admin_users_path, notice: "Usuário removido."
    end

    private

    def user_summary_counts(scope)
      {
        total: scope.count,
        active: scope.active.count,
        sms_rules: NotificationRule.enabled.for_channel("sms").count
      }
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :name, :email_address, :role, :department, :phone_number,
        :password, :password_confirmation,
        :active
      )
    end
  end
end
