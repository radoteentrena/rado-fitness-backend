module Subscriptions
  class MercadoPagoCheckout
    PLAN_KEYS = { basic: :basic, medium: :medium, high_ticket: :high_ticket }.freeze

    def initialize(user, plan_tier)
      @user = user
      @plan_tier = plan_tier.to_sym
    end

    def call
      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )

      response = sdk.preapproval.create(
        "preapproval_plan_id" => plan_id,
        "payer_email"         => @user.email,
        "external_reference"  => @user.id.to_s,
        "back_url"            => Rails.application.routes.url_helpers.subscriptions_processing_url(host: Rails.application.credentials.dig(:app_host))
      )

      if response["status"] == 201
        { success: true, redirect_url: response["response"]["init_point"] }
      else
        error = response.dig("response", "message") || "MercadoPago error"
        Rails.logger.error "MP checkout error for user #{@user.id}: #{error}"
        { success: false, error: error }
      end
    rescue StandardError => e
      Rails.logger.error "MP checkout exception for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def plan_id
      Rails.application.credentials.dig(:mercadopago, :plans, PLAN_KEYS[@plan_tier])
    end
  end
end
