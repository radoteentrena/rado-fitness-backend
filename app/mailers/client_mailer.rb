class ClientMailer < ApplicationMailer
  def welcome(user)
    @user             = user
    @subscription_url = new_subscription_url(host: app_host, protocol: :https)
    mail(
      to:      user.email,
      subject: "Bienvenido, #{user.first_name}. Empezamos."
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
