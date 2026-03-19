module Subscriptions
  class MercadoPagoCheckout
    PLAN_KEYS = { basic: :basic, medium: :medium, high_ticket: :high_ticket }.freeze
    MP_CHECKOUT_BASE = "https://www.mercadopago.com.ar/subscriptions/checkout"

    def initialize(user, plan_tier)
      @user = user
      @plan_tier = plan_tier.to_sym
    end

    def call
      pid = plan_id
      return { success: false, error: "Plan no configurado" } unless pid.present?

      url = "#{MP_CHECKOUT_BASE}?preapproval_plan_id=#{pid}"
      { success: true, redirect_url: url }
    end

    private

    def plan_id
      Rails.application.credentials.dig(:mercadopago, :plans, PLAN_KEYS[@plan_tier])
    end
  end
end
