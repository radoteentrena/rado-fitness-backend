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
    # preapproval_plan checkouts may not propagate external_reference, so fall back
    # to the payer email we attach to every recurring checkout redirect.
    user    = User.find_by(id: mp_data["external_reference"]) ||
              User.find_by(email: mp_data["payer_email"])

    unless user
      Rails.logger.error("[ProcessPaymentEventJob] No user for external_reference=#{mp_data["external_reference"]} payer_email=#{mp_data["payer_email"]} mp_id=#{mp_id}")
      Sentry.capture_message(
        "ProcessPaymentEventJob: no user for external_reference=#{mp_data["external_reference"]} payer_email=#{mp_data["payer_email"]} mp_id=#{mp_id}",
        level: :error
      )
      return
    end

    case status
    when "authorized"
      sub = Subscription.where(user: user, billing_type: :recurring, status: [:active, :pending])
                        .order(:created_at).first_or_initialize
      amount = mp_data.dig("auto_recurring", "transaction_amount")
      amount_cents = amount ? (amount.to_f * 100).to_i : nil

      is_new_subscription = sub.new_record?

      # plan_tier comes from the pending subscription created at checkout; fall back to
      # reverse-mapping the MercadoPago preapproval_plan id. The recurring flow never
      # set user.plan_tier before, so do it here.
      tier = sub.plan_tier.presence || plan_tier_for_preapproval_plan(mp_data["preapproval_plan_id"])
      user.update!(plan_tier: tier) if tier.present? && user.plan_tier != tier

      sub.assign_attributes(
        processor:            :mercadopago,
        plan_tier:            user.plan_tier || tier,
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
      auto_assign_onboarding_defaults(user)

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

      if subscription.promo_link.present?
        subscription.update!(
          access_expires_at: approved_at + 3.months,
          status:            :active
        )
        create_promo_conversion(subscription, approved_at)
      else
        subscription.update!(
          access_expires_at: approved_at + 1.month,
          status:            :active
        )
      end

      user.update!(plan_tier: subscription.plan_tier)
      user.active!
      user.access_active!
      auto_assign_onboarding_defaults(user)
      SubscriptionMailer.confirmed(user, subscription).deliver_later
    when "rejected", "cancelled"
      create_payment_alert(
        user,
        "Pago #{payment["status"]} en MercadoPago (preference: #{preference_id}, payment: #{payment["id"]})."
      )
    end
  end

  # Reverse-maps a MercadoPago preapproval_plan id back to our plan_tier using the
  # credentials map keyed like :basic_monthly / :high_ticket_yearly.
  def plan_tier_for_preapproval_plan(plan_id)
    return nil if plan_id.blank?

    plans = Rails.application.credentials.dig(:mercadopago, :plans) || {}
    key = plans.key(plan_id)
    return nil unless key

    key.to_s.sub(/_(monthly|quarterly|yearly)\z/, "").presence
  end

  def fetch_mp_preapproval(id)
    sdk = Mercadopago::SDK.new(Rails.application.credentials.dig(:mercadopago, :access_token))
    sdk.preapproval.get(id)["response"]
  rescue StandardError => e
    Rails.logger.error("[ProcessPaymentEventJob] MP API error fetching preapproval #{id}: #{e.message}")
    Sentry.capture_exception(e)
    raise
  end

  def create_promo_conversion(subscription, _approved_at)
    promo_link = subscription.promo_link
    full_price = Subscriptions::Pricing.promo_base_price(
      subscription.plan_tier.to_sym, argentina: false
    )

    PromoConversion.find_or_create_by!(referred_user: subscription.user) do |pc|
      pc.promo_link              = promo_link
      pc.subscription            = subscription
      pc.plan_tier               = subscription.plan_tier
      pc.currency                = subscription.currency
      pc.full_price_cents        = (full_price * 100).to_i
      pc.paid_amount_cents       = subscription.amount_cents
      pc.promoter_earnings_cents = (full_price * 100 * 0.25).to_i
    end
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn "[ProcessPaymentEventJob] Duplicate promo conversion for user #{subscription.user_id} — skipped"
  end

  # After payment, basic_tier clients get a default program + dietary plan auto-attached
  # from existing templates. Medium/high-ticket clients are assigned by the coach
  # manually or via the AI Coach.
  def auto_assign_onboarding_defaults(user)
    return unless user.basic?

    assign_default_program(user)
    assign_default_dietary_plan(user)
  end

  # Each assignment is wrapped in its own rescue so a failure never aborts (and retries)
  # payment processing, and a program failure doesn't block the dietary plan or vice versa.
  def assign_default_program(user)
    return if user.programs.exists?

    program = ProgramMatcherService.new(user).call
    Rails.logger.info(
      "[ProcessPaymentEventJob] Auto-assigned program #{program&.id || 'none'} to basic user #{user.id}"
    )
  rescue StandardError => e
    Rails.logger.error(
      "[ProcessPaymentEventJob] Auto-assign program failed for user #{user.id}: #{e.message}"
    )
    Sentry.capture_exception(e)
  end

  # Picks the existing dietary plan whose calorie target is closest to the client's
  # maintenance calories (Harris-Benedict BMR x onboarding activity factor).
  def assign_default_dietary_plan(user)
    return if user.user_dietary_plans.active.exists?

    target = HarrisBenedict.tdee(user)
    return unless target

    plan = DietaryPlan.closest_to_calories(target)
    return unless plan

    plan.assign_to_user(user)
    Rails.logger.info(
      "[ProcessPaymentEventJob] Auto-assigned dietary plan #{plan.id} (~#{target} kcal) to basic user #{user.id}"
    )
  rescue StandardError => e
    Rails.logger.error(
      "[ProcessPaymentEventJob] Auto-assign dietary plan failed for user #{user.id}: #{e.message}"
    )
    Sentry.capture_exception(e)
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
