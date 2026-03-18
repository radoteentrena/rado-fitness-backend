module Subscriptions
  class Cancellation
    def initialize(subscription)
      @subscription = subscription
    end

    def call
      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )
      sdk.preapproval.update(@subscription.external_id, { "status" => "cancelled" })
      @subscription.update!(cancel_at_period_end: true)
      { success: true }
    rescue StandardError => e
      Rails.logger.error "Cancellation error for subscription #{@subscription.id}: #{e.message}"
      { success: false, error: e.message }
    end
  end
end
