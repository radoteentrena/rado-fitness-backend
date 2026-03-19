class ProcessPaymentEventJob < ApplicationJob
  queue_as :default

  def perform(processor:, event_type:, payload:)
    handle_mercadopago(event_type, payload) if processor == "mercadopago"
  rescue StandardError => e
    Rails.logger.error "ProcessPaymentEventJob error [#{processor}/#{event_type}]: #{e.message}"
    raise
  end

  private

  # ── MercadoPago ─────────────────────────────────────────────────────────────

  def handle_mercadopago(event_type, payload)
    case event_type
    when "preapproval" then mercadopago_preapproval(payload)
    when "payment"     then mercadopago_payment(payload)
    end
  end

  def mercadopago_preapproval(payload)
    mp_id   = payload.dig("data", "id")
    mp_data = fetch_mp_preapproval(mp_id)
    status  = mp_data["status"]
    user    = User.find_by!(id: mp_data["external_reference"])

    case status
    when "authorized"
      sub = Subscription.find_or_initialize_by(user: user)
      sub.assign_attributes(
        processor:            :mercadopago,
        plan_tier:            user.plan_tier,
        status:               :active,
        external_id:          mp_id,
        external_customer_id: mp_data["payer_id"].to_s,
        external_plan_id:     mp_data["preapproval_plan_id"],
        currency:             "ARS"
      )
      if (next_date = mp_data["next_payment_date"])
        sub.current_period_end = Time.parse(next_date)
      end
      sub.save!
      user.active!
    when "cancelled"
      sub = Subscription.find_by!(user: user)
      sub.update!(status: :canceled, canceled_at: Time.current)
      user.churned!
    end
  end

  def mercadopago_payment(payload)
    payment_id = payload.dig("data", "id")
    return unless payment_id

    sdk     = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    payment = sdk.payment.get(payment_id)["response"]
    return unless payment["status"] == "rejected"

    preapproval_id = payment["metadata"]&.dig("preapproval_id")
    return unless preapproval_id

    sub = Subscription.find_by!(external_id: preapproval_id)
    sub.past_due!
    CoachAlert.create!(
      user:     sub.user,
      category: :payment_failed,
      message:  "Pago rechazado en MercadoPago para la suscripción #{preapproval_id}.",
      status:   :pending
    )
  end

  def fetch_mp_preapproval(id)
    sdk = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    sdk.preapproval.get(id)["response"]
  end
end
