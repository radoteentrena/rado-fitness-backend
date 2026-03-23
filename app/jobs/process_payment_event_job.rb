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
      sub = Subscription.where(user: user, billing_type: :recurring, status: [:active, :pending])
                        .first_or_initialize
      sub.assign_attributes(
        processor:            :mercadopago,
        plan_tier:            user.plan_tier,
        billing_type:         :recurring,
        status:               :active,
        external_id:          mp_id,
        external_customer_id: mp_data["payer_id"].to_s,
        external_plan_id:     mp_data["preapproval_plan_id"],
        currency:             "ARS",
        reminded_at:          nil,
        past_due_since:       nil
      )
      if (next_date = mp_data["next_payment_date"])
        sub.current_period_end = Time.parse(next_date)
      end
      sub.save!

      # Cancel all other subscriptions for this user
      if sub.persisted?
        user.subscriptions.where.not(id: sub.id).update_all(status: :canceled)
      end

      user.active!
      user.access_active!
    when "cancelled"
      sub = Subscription.find_by!(user: user)
      sub.update!(status: :canceled, canceled_at: Time.current)
      user.churned!
      user.access_locked!
    when "paused"
      Rails.logger.info "MP preapproval paused for user #{user.id} (mp_id: #{mp_id}) — no action taken"
    end
  end

  def mercadopago_payment(payload)
    payment_id = payload.dig("data", "id")
    return unless payment_id

    sdk     = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    payment = sdk.payment.get(payment_id)["response"]

    if payment.dig("metadata", "preapproval_id").present?
      # Preapproval-related payment — only act on rejection
      return unless payment["status"] == "rejected"

      preapproval_id = payment["metadata"]["preapproval_id"]
      sub = Subscription.find_by!(external_id: preapproval_id)
      sub.past_due!
      sub.update!(past_due_since: Time.current)
      CoachAlert.create!(
        user:     sub.user,
        category: :payment_failed,
        message:  "Pago rechazado en MercadoPago para la suscripción #{preapproval_id}.",
        status:   :pending
      )
    else
      handle_checkout_pro_payment(payment)
    end
  end

  def handle_checkout_pro_payment(payment)
    # NOTE: The MP Checkout Pro payment includes "preference_id" at the top level.
    # Verify this key against actual MP SDK response on first test payment.
    preference_id = payment["preference_id"]
    subscription = Subscription.find_by(mp_preference_id: preference_id)

    unless subscription
      Rails.logger.warn "MP Checkout Pro payment: no subscription found for preference_id #{preference_id}"
      return
    end

    user = subscription.user

    case payment["status"]
    when "approved"
      # Cancel all other subscriptions for this user
      user.subscriptions.where.not(id: subscription.id).update_all(status: :canceled)

      subscription.update!(
        access_expires_at: Time.current + 1.month,
        status: :active
      )
      user.active!
      user.access_active!
    when "rejected", "cancelled"
      Rails.logger.info "MP Checkout Pro payment #{payment["status"]} for preference #{preference_id} — no action"
    end
  end

  def fetch_mp_preapproval(id)
    sdk = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    sdk.preapproval.get(id)["response"]
  end
end
