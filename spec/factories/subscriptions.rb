FactoryBot.define do
  factory :subscription do
    association :user
    processor   { :mercadopago }
    plan_tier   { :basic }
    status      { :active }
    currency    { "ARS" }
    amount_cents { 1400000 }
    external_id { "mp_sub_#{SecureRandom.hex(8)}" }
    external_customer_id { "mp_cus_#{SecureRandom.hex(8)}" }
    external_plan_id { "mp_plan_#{SecureRandom.hex(8)}" }
    current_period_end { 30.days.from_now }
    cancel_at_period_end { false }

    trait :past_due do
      status { :past_due }
    end

    trait :canceled do
      status    { :canceled }
      canceled_at { Time.current }
    end
  end
end
