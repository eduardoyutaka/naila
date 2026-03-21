class SessionsController < ApplicationController
  layout "application"

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      start_session(user)
      redirect_to admin_root_path, notice: "Login realizado com sucesso."
    else
      redirect_to login_path, alert: "Email ou senha invalidos."
    end
  end

  def destroy
    end_session
    redirect_to login_path, notice: "Logout realizado com sucesso."
  end
end
