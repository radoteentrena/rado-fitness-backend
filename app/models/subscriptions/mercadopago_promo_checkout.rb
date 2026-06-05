module Subscriptions
  class MercadoPagoPromoCheckout
    ALLOWED_TIERS = %w[medium high_ticket].freeze

    def initialize(user, plan_tier, promo_link)
      @user       = user
      @plan_tier  = plan_tier.to_sym
      @promo_link = promo_link
    end

    def call
      unless ALLOWED_TIERS.include?(@plan_tier.to_s)
        return { success: false, error: "Plan no permitido para promociones" }
      end

      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )

      preference_data = {
        "items" => [{
          "id"          => "rado-promo-#{@plan_tier}",
          "title"       => "Rado Fitness — #{@plan_tier.to_s.humanize} (Plan 3 meses)",
          "description" => "Plan de 3 meses con 25% de descuento",
          "category_id" => "services",
          "quantity"    => 1,
          "currency_id" => Pricing.currency(argentina: false),
          "unit_price"  => paid_amount.to_f
        }],
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
        body = response[:response]
        create_subscription_record(body["id"])
        { success: true, redirect_url: body["init_point"] }
      else
        Rails.logger.error "MP promo checkout error for user #{@user.id}: #{response.inspect}"
        { success: false, error: "MercadoPago error (status #{response[:status]})" }
      end
    rescue StandardError => e
      Rails.logger.error "MP promo checkout exception for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def paid_amount
      @paid_amount ||= Pricing.promo_price(@plan_tier, argentina: false)
    end

    def create_subscription_record(preference_id)
      Subscription.create!(
        user:             @user,
        processor:        :mercadopago,
        plan_tier:        @plan_tier,
        status:           :pending,
        billing_type:     :one_time,
        frequency:        :monthly,
        currency:         "USD",
        amount_cents:     (paid_amount * 100).to_i,
        mp_preference_id: preference_id,
        promo_link:       @promo_link
      )
    end

    def processing_url
      Rails.application.routes.url_helpers.subscriptions_processing_url(
        host:     Rails.application.credentials.dig(:app_host),
        protocol: Rails.env.production? ? :https : :http
      )
    end
  end
end
