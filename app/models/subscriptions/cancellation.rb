module Subscriptions
  class Cancellation
    def initialize(subscription)
      @subscription = subscription
    end

    def call
      if @subscription.stripe?
        cancel_stripe
      else
        cancel_mercadopago
      end
    rescue StandardError => e
      Rails.logger.error "Cancellation error for subscription #{@subscription.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def cancel_stripe
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
      Stripe::Subscription.update(@subscription.external_id, { cancel_at_period_end: true })
      @subscription.update!(cancel_at_period_end: true)
      { success: true }
    end

    def cancel_mercadopago
      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )
      sdk.preapproval.update(@subscription.external_id, { "status" => "cancelled" })
      @subscription.update!(cancel_at_period_end: true)
      { success: true }
    end
  end
end
