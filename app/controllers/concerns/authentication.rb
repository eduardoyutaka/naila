module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
  end

  private

  def current_user
    @current_user ||= Current.user
  end

  def signed_in?
    current_user.present?
  end

  def authenticate!
    resume_session || redirect_to_sign_in
  end

  def resume_session
    session_record = Session.find_by(token: cookies.signed[:session_token])
    if session_record
      Current.user = session_record.user
    end
  end

  def redirect_to_sign_in
    redirect_to login_path, alert: "Voce precisa fazer login para acessar esta pagina."
  end

  def start_session(user)
    session_record = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    cookies.signed.permanent[:session_token] = {
      value: session_record.token,
      httponly: true,
      same_site: :lax
    }
    Current.user = user
  end

  def end_session
    session_record = Session.find_by(token: cookies.signed[:session_token])
    session_record&.destroy
    cookies.delete(:session_token)
    Current.user = nil
  end
end
