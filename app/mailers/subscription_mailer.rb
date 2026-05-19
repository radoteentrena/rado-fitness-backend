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

  def renewed(user, subscription)
    @user          = user
    @subscription  = subscription
    @dashboard_url = root_url(host: app_host, protocol: :https)
    mail(
      to:      user.email,
      subject: "Suscripción renovada. Seguimos."
    )
  end
end
