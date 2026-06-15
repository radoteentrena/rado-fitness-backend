class PaymentsController < ApplicationController
  layout "homepage"

  def show
    user = User.find_by(payment_link_token: params[:token])

    unless user&.payment_token_valid?
      redirect_to root_path, alert: "Este link de pago no es válido o ha expirado."
      return
    end

    sign_in(user)
    user.consume_payment_token!
    redirect_to new_subscription_path
  end
end
