module Subscriptions
  class StripeCheckout
    PLAN_PRICES = {
      basic:       -> { Rails.application.credentials.dig(:stripe, :prices, :basic) },
      medium:      -> { Rails.application.credentials.dig(:stripe, :prices, :medium) },
      high_ticket: -> { Rails.application.credentials.dig(:stripe, :prices, :high_ticket) }
    }.freeze

    PLAN_AMOUNTS = { basic: 1000, medium: 5000, high_ticket: 10000 }.freeze

    def initialize(user, plan_tier)
      @user = user
      @plan_tier = plan_tier.to_sym
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
    end

    def call
      customer = Stripe::Customer.create(
        email: @user.email,
        name: @user.name,
        metadata: { user_id: @user.id }
      )

      session = Stripe::Checkout::Session.create(
        customer: customer.id,
        client_reference_id: @user.id.to_s,
        mode: "subscription",
        line_items: [ { price: price_id, quantity: 1 } ],
        success_url: Rails.application.routes.url_helpers.subscriptions_processing_url(host: Rails.application.credentials.app_host),
        cancel_url: Rails.application.routes.url_helpers.new_subscription_url(host: Rails.application.credentials.app_host),
        subscription_data: {
          metadata: { user_id: @user.id, plan_tier: @plan_tier }
        }
      )

      { success: true, redirect_url: session.url }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe checkout error for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def price_id
      PLAN_PRICES[@plan_tier].call
    end
  end
end
