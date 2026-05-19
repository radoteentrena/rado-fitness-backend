class SubscriptionMailer < ApplicationMailer
  def confirmed(user, subscription)
    @user          = user
    @subscription  = subscription
    @dashboard_url = root_url(host: app_host, protocol: :https)
    mail(
      to:      user.email,
      subject: "Acceso activado. Estás adentro."
    )
  end

  private

  def app_host
    host = Rails.application.credentials.dig(:app_host)
    raise "Missing credential: app_host — required for subscription mailer URLs" if host.blank?
    host
  end
end
