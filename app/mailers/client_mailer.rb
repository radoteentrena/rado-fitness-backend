class ClientMailer < ApplicationMailer
  def welcome(user, temp_password = nil)
    @user             = user
    @temp_password    = temp_password
    @subscription_url = new_subscription_url(host: app_host, protocol: :https)
    @app_store_url    = "https://apps.apple.com/app/rado-te-entrena"
    @play_store_url   = "https://play.google.com/store/apps/details?id=com.radoteentrena"
    mail(
      to:      user.email,
      subject: "Bienvenido, #{user.first_name}. Empezamos."
    )
  end

  def payment_link(user)
    @user        = user
    token        = user.generate_payment_token!
    @payment_url = pay_url(token: token, host: app_host, protocol: :https)
    mail(
      to:      user.email,
      subject: "Tu acceso a Rado Te Entrena"
    )
  end

  def call_booked(user, appointment_time, calendar_url)
    @user             = user
    @appointment_time = appointment_time
    @calendar_url     = calendar_url
    mail(
      to:      user.email,
      subject: "Tu llamada está confirmada"
    )
  end
end
