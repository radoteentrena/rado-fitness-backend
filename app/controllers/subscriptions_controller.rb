class SubscriptionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!
  layout "homepage"

  VALID_PLAN_TIERS    = %w[basic medium high_ticket].freeze
  VALID_BILLING_TYPES = %w[one_time recurring].freeze
  VALID_FREQUENCIES   = %w[monthly quarterly yearly].freeze

  def new
    @argentina = current_user.onboarding_profile&.argentina?
  end

  def frequency
    @plan_tier = validated_plan_tier
    if @plan_tier.nil?
      redirect_to new_subscription_path, alert: "Plan inválido. Por favor elegí una opción."
      return
    end

    @argentina = current_user.onboarding_profile&.argentina?
    symbol     = Subscriptions::Pricing.currency_symbol(argentina: @argentina)

    @options = [
      {
        label:        "Pago único (1 mes)",
        billing_type: "one_time",
        frequency:    "monthly",
        price:        "#{symbol}#{number_with_delimiter(Subscriptions::Pricing.effective_price(@plan_tier, :one_time, :monthly, argentina: @argentina))}",
        subtitle:     nil,
        badge:        nil
      },
      {
        label:        "Mensual",
        billing_type: "recurring",
        frequency:    "monthly",
        price:        "#{symbol}#{number_with_delimiter(Subscriptions::Pricing.effective_price(@plan_tier, :recurring, :monthly, argentina: @argentina))}",
        subtitle:     "/ mes",
        badge:        nil
      },
      {
        label:        "Trimestral",
        billing_type: "recurring",
        frequency:    "quarterly",
        price:        "#{symbol}#{number_with_delimiter(Subscriptions::Pricing.effective_price(@plan_tier, :recurring, :quarterly, argentina: @argentina))}",
        subtitle:     "/ mes",
        badge:        "5% off"
      },
      {
        label:        "Anual",
        billing_type: "recurring",
        frequency:    "yearly",
        price:        "#{symbol}#{number_with_delimiter(Subscriptions::Pricing.effective_price(@plan_tier, :recurring, :yearly, argentina: @argentina))}",
        subtitle:     "/ mes",
        badge:        "10% off"
      }
    ]
  end

  def create
    plan = validated_plan_tier
    if plan.nil?
      redirect_to new_subscription_path, alert: "Plan inválido. Por favor elegí una opción."
      return
    end

    billing_type = params[:billing_type]
    frequency    = params[:frequency]

    unless VALID_BILLING_TYPES.include?(billing_type) && VALID_FREQUENCIES.include?(frequency)
      redirect_to subscription_frequency_path(plan_tier: plan), alert: "Seleccioná una frecuencia válida."
      return
    end

    result = if billing_type == "one_time"
      Subscriptions::MercadoPagoOneTimeCheckout.new(current_user, plan, frequency).call
    else
      Subscriptions::MercadoPagoCheckout.new(current_user, plan, frequency).call
    end

    if result[:success]
      redirect_to result[:redirect_url], allow_other_host: true
    else
      redirect_to new_subscription_path, alert: "Hubo un error al procesar el pago. Intentá de nuevo."
    end
  end

  def processing
    status = params[:collection_status].presence || params[:status]

    case status
    when "approved"
      activate_one_time_subscription_if_pending
      if current_user&.medium_or_high_ticket? && current_user.booking.nil?
        redirect_to new_booking_path, notice: "¡Pago confirmado! Agendá tu llamada de inicio."
      else
        redirect_to root_path, notice: "¡Pago confirmado! Tu suscripción ya está activa."
      end
    when "rejected", "cancelled"
      redirect_to new_subscription_path, alert: "El pago fue rechazado. Verificá tus datos e intentá de nuevo."
    when "pending", "in_process"
      redirect_to root_path, notice: "Tu pago está siendo procesado. Te avisaremos cuando se confirme."
    else
      redirect_to root_path, notice: "Recibimos tu solicitud. Te contactaremos pronto."
    end
  end

  private

  def activate_one_time_subscription_if_pending
    preference_id = params[:preference_id]
    collection_id  = params[:collection_id]

    # collection_id is the MP payment ID — only present on a real payment redirect
    return unless preference_id.present? && collection_id.present? && collection_id != "null"

    subscription = current_user.subscriptions.find_by(
      mp_preference_id: preference_id,
      billing_type:     :one_time,
      status:           :pending
    )
    return unless subscription

    subscription.update!(status: :active, access_expires_at: Time.current + 1.month)
    current_user.subscriptions.where.not(id: subscription.id).update_all(status: :canceled)
    current_user.update!(plan_tier: subscription.plan_tier)
    current_user.active!
    current_user.access_active!
  end

  def validated_plan_tier
    tier = params[:plan_tier]
    VALID_PLAN_TIERS.include?(tier) ? tier : nil
  end
end
