class SubscriptionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!
  layout "homepage"

  VALID_PLAN_TIERS = %w[basic medium high_ticket].freeze
  VALID_BILLING_TYPES = %w[one_time recurring].freeze
  VALID_FREQUENCIES = %w[monthly quarterly yearly].freeze

  BASE_PRICES_ARS = { "basic" => 14_000, "medium" => 70_000, "high_ticket" => 140_000 }.freeze
  BASE_PRICES_USD = { "basic" => 10, "medium" => 50, "high_ticket" => 100 }.freeze

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
    base = @argentina ? BASE_PRICES_ARS[@plan_tier] : BASE_PRICES_USD[@plan_tier]
    currency_symbol = @argentina ? "$" : "US$"

    @options = [
      {
        label: "Pago único (1 mes)",
        billing_type: "one_time",
        frequency: "monthly",
        price: "#{currency_symbol}#{number_with_delimiter(base)}",
        subtitle: nil,
        badge: nil
      },
      {
        label: "Mensual",
        billing_type: "recurring",
        frequency: "monthly",
        price: "#{currency_symbol}#{number_with_delimiter(base)}",
        subtitle: "/ mes",
        badge: nil
      },
      {
        label: "Trimestral",
        billing_type: "recurring",
        frequency: "quarterly",
        price: "#{currency_symbol}#{number_with_delimiter((base * 0.95).round)}",
        subtitle: "/ mes",
        badge: "5% off"
      },
      {
        label: "Anual",
        billing_type: "recurring",
        frequency: "yearly",
        price: "#{currency_symbol}#{number_with_delimiter((base * 0.90).round)}",
        subtitle: "/ mes",
        badge: "10% off"
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

  def processing; end

  private

  def validated_plan_tier
    tier = params[:plan_tier]
    VALID_PLAN_TIERS.include?(tier) ? tier : nil
  end
end
