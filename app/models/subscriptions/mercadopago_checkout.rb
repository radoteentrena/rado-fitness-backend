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

      sdk = Mercadopago::SDK.new(
        Rails.application.credentials.dig(:mercadopago, :access_token)
      )

      response = sdk.preapproval_plan.get(pid)

      if response[:status] == 200
        init_point = response[:response]["init_point"]
        separator = init_point.include?("?") ? "&" : "?"
        redirect_url = "#{init_point}#{separator}payer_email=#{CGI.escape(@user.email)}"
        { success: true, redirect_url: redirect_url }
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
