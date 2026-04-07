module Admin
  class BaseController < ApplicationController
    include Pundit::Authorization

    before_action :authenticate!

    after_action :verify_authorized

    layout "admin"

    rescue_from Pundit::NotAuthorizedError, with: :not_authorized

    private

    def pundit_user
      current_user
    end

    def not_authorized
      redirect_to admin_root_path, alert: "Você não tem permissão para realizar esta ação."
    end
  end
end
