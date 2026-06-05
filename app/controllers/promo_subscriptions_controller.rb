class PromoSubscriptionsController < ApplicationController
  layout "homepage"
  before_action :authenticate_user!
  before_action :require_promo_session

  def new
    @promo_link = PromoLink.active.find_by(code: session[:promo_code])
    redirect_to(new_subscription_path) and return unless @promo_link

    @prices = {
      medium: {
        full_price: Subscriptions::Pricing.promo_base_price(:medium,      argentina: false),
        discounted: Subscriptions::Pricing.promo_price(:medium,           argentina: false),
        currency:   "USD"
      },
      high_ticket: {
        full_price: Subscriptions::Pricing.promo_base_price(:high_ticket, argentina: false),
        discounted: Subscriptions::Pricing.promo_price(:high_ticket,      argentina: false),
        currency:   "USD"
      }
    }
  end

  def create
    promo_link = PromoLink.active.find_by(code: session[:promo_code])
    unless promo_link
      redirect_to new_subscription_path, alert: "El enlace promocional ya no es válido."
      return
    end

    plan_tier = params[:plan_tier].to_s
    unless %w[medium high_ticket].include?(plan_tier)
      redirect_to new_promo_subscription_path, alert: "Plan no válido."
      return
    end

    result = Subscriptions::MercadoPagoPromoCheckout.new(current_user, plan_tier, promo_link).call

    if result[:success]
      session.delete(:promo_code)
      redirect_to result[:redirect_url], allow_other_host: true
    else
      redirect_to new_promo_subscription_path, alert: "Error al procesar el pago. Intenta de nuevo."
    end
  end

  private

  def require_promo_session
    redirect_to new_subscription_path unless session[:promo_code].present?
  end
end
