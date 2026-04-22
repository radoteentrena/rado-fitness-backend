module Subscriptions
  class MercadoPagoCheckout
    def initialize(user, plan_tier, frequency = "monthly")
      @user = user
      @plan_tier = plan_tier.to_sym
      @frequency = frequency.to_s
    end

    def call
      pid = plan_id
      return { success: false, error: "Plan no configurado" } unless pid.present?

      response = sdk.preapproval.create(
        "preapproval_plan_id" => plan_id,
        "payer_email"         => @user.email,
        "external_reference"  => @user.id.to_s,
        "back_url"            => Rails.application.routes.url_helpers.subscriptions_processing_url(host: Rails.application.credentials.dig(:app_host))
      )

      if response[:status] == 201
        { success: true, redirect_url: response[:response]["init_point"] }
      else
        Rails.logger.error "MP checkout error for user #{@user.id}: #{response.inspect}"
        { success: false, error: "MercadoPago error (status #{response[:status]})" }
      end
    rescue StandardError => e
      Rails.logger.error "MP checkout exception for user #{@user.id}: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def plan_id
      key = :"#{@plan_tier}_#{@frequency}"
      Rails.application.credentials.dig(:mercadopago, :plans, key)
    end
  end
end
