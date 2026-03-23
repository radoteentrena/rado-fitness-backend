module Subscriptions
  class MercadoPagoOneTimeCheckout
    def initialize(user, plan_tier, frequency = "monthly")
      @user = user
      @plan_tier = plan_tier.to_sym
      @frequency = frequency.to_s # always "monthly" for one_time
    end

    def call
      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )

      subscription = create_subscription_record

      preference_data = {
        "items" => [
          {
            "title" => "Rado Fitness — #{@plan_tier.to_s.humanize} (Pago único)",
            "quantity" => 1,
            "currency_id" => currency,
            "unit_price" => total_amount
          }
        ],
        "payer" => {
          "email" => @user.email
        },
        "external_reference" => @user.id.to_s,
        "back_urls" => {
          "success" => processing_url,
          "failure" => processing_url,
          "pending" => processing_url
        },
        "auto_return" => "approved"
      }

      response = sdk.preference.create(preference_data)

      if response[:status] == 201
        body = response[:response]
        preference_id = body["id"]
        subscription.update!(mp_preference_id: preference_id)
        { success: true, redirect_url: body["init_point"] }
      else
        Rails.logger.error "MP one-time checkout error for user #{@user.id}: #{response.inspect}"
        subscription.destroy
        { success: false, error: "MercadoPago error (status #{response[:status]})" }
      end
    rescue StandardError => e
      Rails.logger.error "MP one-time checkout exception for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def create_subscription_record
      Subscription.create!(
        user: @user,
        processor: :mercadopago,
        plan_tier: @plan_tier,
        status: :pending,
        billing_type: :one_time,
        frequency: :monthly,
        currency: currency,
        amount_cents: (total_amount * 100).to_i
      )
    end

    def total_amount
      @total_amount ||= base_price.to_f
    end

    def base_price
      prices = if @user.onboarding_profile&.argentina?
        { basic: 14_000, medium: 70_000, high_ticket: 140_000 }
      else
        { basic: 10, medium: 50, high_ticket: 100 }
      end
      prices[@plan_tier]
    end

    def currency
      @user.onboarding_profile&.argentina? ? "ARS" : "USD"
    end

    def processing_url
      Rails.application.routes.url_helpers.subscriptions_processing_url(
        host: Rails.application.credentials.dig(:app_host),
        protocol: :https
      )
    end
  end
end
