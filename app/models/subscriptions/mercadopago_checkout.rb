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
        # Persist a pending subscription so the preapproval webhook can resolve the
        # user and the chosen plan_tier (the preapproval_plan init_point carries no
        # plan_tier of ours, and external_reference may not propagate reliably).
        upsert_pending_subscription(pid)

        init_point = response[:response]["init_point"]
        separator = init_point.include?("?") ? "&" : "?"
        redirect_url = "#{init_point}#{separator}payer_email=#{CGI.escape(@user.email)}" \
                       "&external_reference=#{@user.id}"
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

    def upsert_pending_subscription(plan_id)
      sub = @user.subscriptions.where(billing_type: :recurring, status: :pending).first_or_initialize
      sub.update!(
        processor:        :mercadopago,
        plan_tier:        @plan_tier,
        frequency:        @frequency,
        currency:         Pricing.currency(argentina: argentina?),
        amount_cents:     (Pricing.effective_price(@plan_tier, :recurring, @frequency, argentina: argentina?).to_f * 100).to_i,
        external_plan_id: plan_id
      )
    end

    def argentina?
      @argentina ||= @user.onboarding_profile&.argentina?
    end

    def plan_id
      key = :"#{@plan_tier}_#{@frequency}"
      Rails.application.credentials.dig(:mercadopago, :plans, key)
    end
  end
end
