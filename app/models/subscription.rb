class Subscription < ApplicationRecord
  belongs_to :user

  enum :processor, { mercadopago: 0 }
  enum :plan_tier, { basic: 0, medium: 1, high_ticket: 2 }
  enum :status, { pending: 0, active: 1, past_due: 2, canceled: 3 }
  enum :billing_type, { recurring: 0, one_time: 1 }
  enum :frequency, { monthly: 0, quarterly: 1, yearly: 2 }

  validates :processor, presence: true
  validates :plan_tier, presence: true
  validates :frequency, inclusion: { in: %w[monthly], message: "must be monthly for one-time payments" }, if: -> { one_time? }

  def amount_in_dollars
    return 0.0 unless amount_cents
    amount_cents / 100.0
  end
end
