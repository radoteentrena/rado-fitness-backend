module Subscriptions
  class MercadoPagoOneTimeCheckout
    def initialize(user, plan_tier, frequency = "monthly")
      @user      = user
      @plan_tier = plan_tier.to_sym
      @frequency = frequency.to_s
    end

    def call
      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )

      preference_data = {
        "items" => [
          {
            "title"       => "Rado Fitness — #{@plan_tier.to_s.humanize} (Pago único)",
            "quantity"    => 1,
            "currency_id" => Pricing.currency(argentina: argentina?),
            "unit_price"  => total_amount
          }
        ],
        "payer"              => { "email" => @user.email },
        "external_reference" => @user.id.to_s,
        "back_urls"          => {
          "success" => processing_url,
          "failure" => processing_url,
          "pending" => processing_url
        },
        "auto_return" => "approved"
      }

      response = sdk.preference.create(preference_data)

      if response[:status] == 201
        body          = response[:response]
        preference_id = body["id"]
        create_subscription_record(preference_id)
        { success: true, redirect_url: body["init_point"] }
      else
        Rails.logger.error "MP one-time checkout error for user #{@user.id}: #{response.inspect}"
        { success: false, error: "MercadoPago error (status #{response[:status]})" }
      end
    rescue StandardError => e
      Rails.logger.error "MP one-time checkout exception for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def create_subscription_record(preference_id)
      Subscription.create!(
        user:             @user,
        processor:        :mercadopago,
        plan_tier:        @plan_tier,
        status:           :pending,
        billing_type:     :one_time,
        frequency:        :monthly,
        currency:         Pricing.currency(argentina: argentina?),
        amount_cents:     (total_amount * 100).to_i,
        mp_preference_id: preference_id
      )
    end

    def total_amount
      @total_amount ||= Pricing.effective_price(@plan_tier, :one_time, :monthly, argentina: argentina?).to_f
    end

    def argentina?
      @argentina ||= @user.onboarding_profile&.argentina?
    end

    def processing_url
      Rails.application.routes.url_helpers.subscriptions_processing_url(
        host:     Rails.application.credentials.dig(:app_host),
        protocol: :https
      )
    end
  end
end
