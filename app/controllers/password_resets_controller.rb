class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user
      PasswordResetMailer.reset_instructions(user).deliver_later
    end
    # Always show the same message to prevent email enumeration
    redirect_to login_path, notice: "Se esse email estiver cadastrado, você receberá as instruções em breve."
  end

  def edit
    @user = find_user_by_token
    redirect_to new_password_reset_path, alert: "Link inválido ou expirado." unless @user
  end

  def update
    @user = find_user_by_token
    unless @user
      redirect_to new_password_reset_path, alert: "Link inválido ou expirado." and return
    end

    if @user.update(password_params)
      @user.sessions.destroy_all
      redirect_to login_path, notice: "Senha redefinida com sucesso. Faça login com a nova senha."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_token
    User.find_by_password_reset_token(params[:token])
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
