module Subscriptions
  module Pricing
    PRICES_ARS = { basic: 14_000, medium: 70_000, high_ticket: 140_000 }.freeze
    PRICES_USD = { basic: 10,     medium: 50,     high_ticket: 100      }.freeze

    DISCOUNTS = { monthly: 1.0, quarterly: 0.95, yearly: 0.90 }.freeze

    def self.base_price(plan_tier, argentina:)
      table = argentina ? PRICES_ARS : PRICES_USD
      table.fetch(plan_tier.to_sym)
    end

    def self.effective_price(plan_tier, billing_type, frequency, argentina:)
      base = base_price(plan_tier, argentina: argentina)
      multiplier = billing_type.to_sym == :one_time ? 1.0 : DISCOUNTS.fetch(frequency.to_sym, 1.0)
      (base * multiplier).round
    end

    def self.currency(argentina:)
      argentina ? "ARS" : "USD"
    end

    def self.currency_symbol(argentina:)
      argentina ? "$" : "US$"
    end
  end
end
