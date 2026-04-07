module Admin
  class UsersController < BaseController
    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_user, only: [:edit, :update, :destroy]
    before_action -> { authorize User }, only: [:index, :new, :create]
    before_action -> { authorize @user }, only: [:edit, :update, :destroy]

    def index
      @users = policy_scope(User).order(:name).includes(:sessions)
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

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :name, :email_address, :role, :department, :phone_number,
        :password, :password_confirmation,
        :active, :receives_sms_alerts
      )
    end
  end
end
