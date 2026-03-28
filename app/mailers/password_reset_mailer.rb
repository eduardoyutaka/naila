class PasswordResetMailer < ApplicationMailer
  def reset_instructions(user)
    @user = user
    @reset_url = edit_password_reset_url(user.password_reset_token)
    mail(to: user.email_address, subject: "Redefinição de senha — NAILA")
  end
end
