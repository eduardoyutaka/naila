class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.dig(:mailer, :from) || "NAILA — Defesa Civil <noreply@nailariscos.com>" }
  layout "mailer"
end
