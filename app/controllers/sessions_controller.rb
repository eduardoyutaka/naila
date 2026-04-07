class SessionsController < ApplicationController
  layout "application"

  def new
    @sensors_online = Rails.cache.fetch("sensors_online_count", expires_in: 5.minutes) { MonitoringStation.online.count }
    @river_basins_count = Rails.cache.fetch("river_basins_count", expires_in: 1.hour) { RiverBasin.count }
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      start_session(user)
      redirect_to admin_root_path, notice: "Login realizado com sucesso."
    else
      redirect_to login_path, alert: "Email ou senha inválidos."
    end
  end

  def destroy
    end_session
    redirect_to login_path, notice: "Logout realizado com sucesso."
  end
end
