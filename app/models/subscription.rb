class Subscription < ApplicationRecord
  belongs_to :user

  enum :processor, { mercadopago: 0 }
  enum :plan_tier, { basic: 0, medium: 1, high_ticket: 2 }
  enum :status, { pending: 0, active: 1, past_due: 2, canceled: 3 }
  enum :billing_type, { recurring: 0, one_time: 1 }
  enum :frequency, { monthly: 0, quarterly: 1, yearly: 2 }

  validates :processor, presence: true
  validates :plan_tier, presence: true

  validate :one_time_requires_monthly_frequency, if: -> { one_time? }

  def amount_in_dollars
    if amount_cents.present? && amount_cents > 0
      amount_cents / 100.0
    else
      argentina = (currency == "ARS")
      begin
        Subscriptions::Pricing.effective_price(plan_tier, billing_type || :recurring, frequency || :monthly, argentina: argentina).to_f
      rescue
        0.0
      end
    end
  end

  private

  def one_time_requires_monthly_frequency
    errors.add(:frequency, "must be monthly for one-time payments") unless monthly?
  end
end
