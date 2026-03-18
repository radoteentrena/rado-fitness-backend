class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  layout "homepage"

  VALID_PLAN_TIERS = %w[basic medium high_ticket].freeze

  def new
    @argentina = current_user.onboarding_profile&.argentina?
  end

  def create
    plan = validated_plan_tier
    if plan.nil?
      redirect_to new_subscription_path, alert: "Plan inválido. Por favor elegí una opción."
      return
    end

    result = Subscriptions::MercadoPagoCheckout.new(current_user, plan).call
    if result[:success]
      redirect_to result[:redirect_url], allow_other_host: true
    else
      redirect_to new_subscription_path, alert: "Hubo un error al procesar el pago. Intentá de nuevo."
    end
  end

  def processing; end

  private

  def validated_plan_tier
    tier = params[:plan_tier]
    VALID_PLAN_TIERS.include?(tier) ? tier : nil
  end
end
