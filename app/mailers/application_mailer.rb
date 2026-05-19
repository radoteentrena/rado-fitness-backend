class ApplicationMailer < ActionMailer::Base
  default from: "Rado Te Entrena <info@radoteentrena.com>"
  layout "mailer"

  private

  def app_host
    host = Rails.application.credentials.dig(:app_host)
    raise "Missing credential: app_host" if host.blank?
    host
  end
end
