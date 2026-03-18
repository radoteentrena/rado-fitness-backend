FactoryBot.define do
  factory :subscription do
    association :user
    processor   { :stripe }
    plan_tier   { :basic }
    status      { :active }
    currency    { "USD" }
    amount_cents { 1000 }
    external_id { "sub_test_#{SecureRandom.hex(8)}" }
    external_customer_id { "cus_test_#{SecureRandom.hex(8)}" }
    external_plan_id { "price_test_#{SecureRandom.hex(8)}" }
    current_period_end { 30.days.from_now }
    cancel_at_period_end { false }

    trait :mercadopago do
      processor { :mercadopago }
      currency  { "ARS" }
      amount_cents { 900000 }
    end

    trait :past_due do
      status { :past_due }
    end

    trait :canceled do
      status    { :canceled }
      canceled_at { Time.current }
    end
  end
end
