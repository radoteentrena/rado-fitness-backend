class ClientMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @subscription_url = new_subscription_url
    mail(
      to: user.email,
      subject: "Bienvenido, #{user.first_name}. Empezamos."
    )
  end
end
