class ProcessPaymentEventJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3, wait: :polynomially_longer

  def perform(processor:, event_type:, payload:)
    handle_mercadopago(event_type, payload) if processor == "mercadopago"
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
    user    = User.find_by(id: mp_data["external_reference"])

    unless user
      Rails.logger.error("[ProcessPaymentEventJob] No user for external_reference=#{mp_data["external_reference"]} mp_id=#{mp_id}")
      Sentry.capture_message(
        "ProcessPaymentEventJob: no user for external_reference=#{mp_data["external_reference"]} mp_id=#{mp_id}",
        level: :error
      )
      return
    end

    case status
    when "authorized"
      sub = Subscription.where(user: user, billing_type: :recurring, status: [:active, :pending])
                        .first_or_initialize
      amount = mp_data.dig("auto_recurring", "transaction_amount")
      amount_cents = amount ? (amount.to_f * 100).to_i : nil

      is_new_subscription = sub.new_record?

      sub.assign_attributes(
        processor:            :mercadopago,
        plan_tier:            user.plan_tier,
        billing_type:         :recurring,
        status:               :active,
        external_id:          mp_id,
        external_customer_id: mp_data["payer_id"].to_s,
        external_plan_id:     mp_data["preapproval_plan_id"],
        currency:             user.onboarding_profile&.argentina? ? "ARS" : "USD",
        amount_cents:         amount_cents,
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

      Turbo::StreamsChannel.broadcast_append_to(
        "admin_payment_events",
        target: "admin_toast_container",
        partial: "admin/shared/payment_toast",
        locals: { toast_type: :authorized, message: "#{user.email} — suscripción activada" }
      )

      if is_new_subscription
        SubscriptionMailer.confirmed(user, sub).deliver_later
      else
        SubscriptionMailer.renewed(user, sub).deliver_later
      end
    when "cancelled"
      sub = Subscription.find_by!(external_id: mp_id)
      sub.update!(status: :canceled, canceled_at: Time.current)
      user.churned!

      Turbo::StreamsChannel.broadcast_append_to(
        "admin_payment_events",
        target: "admin_toast_container",
        partial: "admin/shared/payment_toast",
        locals: { toast_type: :cancelled, message: "#{user.email} — suscripción cancelada" }
      )
      if sub.current_period_end.nil? || sub.current_period_end <= Time.current
        user.access_locked!
      else
        Rails.logger.info "Preapproval #{mp_id} cancelled but period ends #{sub.current_period_end} — " \
                          "deferring access lock to dunning job"
      end
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
    # MP Checkout Pro payments include "preference_id" at the top level of the payment object.
    # If MP changes the payload structure, check their payment.get SDK response under payment["preference_id"].
    preference_id = payment["preference_id"]

    unless preference_id.present?
      Rails.logger.error "MP Checkout Pro payment #{payment["id"]}: missing preference_id in payload. " \
                         "Full payment keys: #{payment.keys.inspect}"
      return
    end

    subscription = Subscription.find_by(mp_preference_id: preference_id)

    unless subscription
      Rails.logger.warn "MP Checkout Pro payment #{payment["id"]}: no subscription found for " \
                        "preference_id=#{preference_id}. Payment may have been created outside this system."
      return
    end

    user = subscription.user

    case payment["status"]
    when "approved"
      user.subscriptions.where.not(id: subscription.id).update_all(status: :canceled)

      approved_at = payment["date_approved"].present? ? Time.parse(payment["date_approved"]) : Time.current

      subscription.update!(
        access_expires_at: approved_at + 1.month,
        status:            :active
      )
      user.active!
      user.access_active!
      SubscriptionMailer.confirmed(user, subscription).deliver_later
    when "rejected", "cancelled"
      create_payment_alert(
        user,
        "Pago #{payment["status"]} en MercadoPago (preference: #{preference_id}, payment: #{payment["id"]})."
      )
    end
  end

  def fetch_mp_preapproval(id)
    sdk = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    sdk.preapproval.get(id)["response"]
  rescue StandardError => e
    Rails.logger.error("[ProcessPaymentEventJob] MP API error fetching preapproval #{id}: #{e.message}")
    Sentry.capture_exception(e)
    raise
  end

  def create_payment_alert(user, message)
    return unless user

    CoachAlert.create!(
      user:     user,
      category: :payment_failed,
      message:  message,
      status:   :pending
    )
  rescue StandardError => e
    Rails.logger.error("[ProcessPaymentEventJob] Could not create CoachAlert for user #{user&.id}: #{e.message}")
    Sentry.capture_exception(e)
  end
end
