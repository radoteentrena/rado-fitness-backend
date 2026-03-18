class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    result = checkout.call

    if result[:success]
      redirect_to result[:redirect_url], allow_other_host: true
    else
      redirect_to new_subscription_path, alert: "Hubo un error al procesar el pago. Intentá de nuevo."
    end
  end

  def processing
  end

  private

  def checkout
    if current_user.onboarding_profile&.argentina?
      Subscriptions::MercadoPagoCheckout.new(current_user, current_user.plan_tier)
    else
      Subscriptions::StripeCheckout.new(current_user, current_user.plan_tier)
    end
  end
end
