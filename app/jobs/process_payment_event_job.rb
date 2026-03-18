class ProcessPaymentEventJob < ApplicationJob
  queue_as :default

  def perform(processor:, event_type:, payload:)
    case processor
    when "stripe"      then handle_stripe(event_type, payload)
    when "mercadopago" then handle_mercadopago(event_type, payload)
    end
  rescue StandardError => e
    Rails.logger.error "ProcessPaymentEventJob error [#{processor}/#{event_type}]: #{e.message}"
    raise
  end

  private

  # ── Stripe ─────────────────────────────────────────────────────────────────

  def handle_stripe(event_type, payload)
    case event_type
    when "checkout.session.completed"    then stripe_checkout_completed(payload)
    when "invoice.payment_succeeded"     then stripe_payment_succeeded(payload)
    when "invoice.payment_failed"        then stripe_payment_failed(payload)
    when "customer.subscription.deleted" then stripe_subscription_deleted(payload)
    end
  end

  def stripe_checkout_completed(payload)
    user = User.find_by!(id: payload["client_reference_id"])
    sub  = Subscription.find_or_initialize_by(user: user)

    sub.assign_attributes(
      processor:            :stripe,
      plan_tier:            user.plan_tier,
      status:               :active,
      external_id:          payload["subscription"],
      external_customer_id: payload["customer"],
      currency:             payload["currency"]&.upcase || "USD",
      amount_cents:         payload["amount_subtotal"]
    )
    sub.save!
    user.active!
  end

  def stripe_payment_succeeded(payload)
    sub = Subscription.find_by!(external_id: payload["subscription"])
    period_end = payload.dig("lines", "data", 0, "period", "end")
    sub.update!(current_period_end: Time.at(period_end)) if period_end
  end

  def stripe_payment_failed(payload)
    sub = Subscription.find_by!(external_id: payload["subscription"])
    sub.past_due!
    CoachAlert.create!(
      user:     sub.user,
      category: :payment_failed,
      message:  "Pago fallido en Stripe para la suscripción #{sub.external_id}.",
      status:   :pending
    )
  end

  def stripe_subscription_deleted(payload)
    sub = Subscription.find_by!(external_id: payload["id"])
    sub.update!(status: :canceled, canceled_at: Time.current)
    sub.user.churned!
  end

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
