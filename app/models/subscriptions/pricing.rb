module Subscriptions
  module Pricing
    PRICES_ARS = { basic: 14_000, medium: 70_000, high_ticket: 140_000 }.freeze
    PRICES_USD = { basic: 10,     medium: 50,     high_ticket: 100      }.freeze

    DISCOUNTS = { monthly: 1.0, quarterly: 0.95, yearly: 0.90 }.freeze

    PROMO_DISCOUNT = 0.75
    PROMOTER_RATE  = 0.25

    def self.promo_base_price(plan_tier, argentina:)
      base_price(plan_tier, argentina: argentina) * 3
    end

    def self.promo_price(plan_tier, argentina:)
      (promo_base_price(plan_tier, argentina: argentina) * PROMO_DISCOUNT).round
    end

    def self.promoter_earnings(plan_tier, argentina:)
      (promo_base_price(plan_tier, argentina: argentina) * PROMOTER_RATE).round
    end

    def self.base_price(plan_tier, argentina:)
      table = argentina ? PRICES_ARS : PRICES_USD
      table.fetch(plan_tier.to_sym) { raise ArgumentError, "Invalid plan_tier: #{plan_tier}" }
    end

    def self.effective_price(plan_tier, billing_type, frequency, argentina:)
      base = base_price(plan_tier, argentina: argentina)
      if billing_type.to_sym == :one_time
        base
      else
        multiplier = DISCOUNTS.fetch(frequency.to_sym) { raise ArgumentError, "Invalid frequency: #{frequency}" }
        (base * multiplier).round
      end
    end

    def self.currency(argentina:)
      argentina ? "ARS" : "USD"
    end

    def self.currency_symbol(argentina:)
      argentina ? "$" : "US$"
    end
  end
end
