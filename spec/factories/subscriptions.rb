FactoryBot.define do
  factory :subscription do
    association :user
    processor   { :mercadopago }
    plan_tier   { :basic }
    status      { :active }
    billing_type { :recurring }
    frequency   { :monthly }
    currency    { "ARS" }
    amount_cents { 1400000 }
    external_id { "mp_sub_#{SecureRandom.hex(8)}" }
    external_customer_id { "mp_cus_#{SecureRandom.hex(8)}" }
    external_plan_id { "mp_plan_#{SecureRandom.hex(8)}" }
    current_period_end { 30.days.from_now }
    cancel_at_period_end { false }

    trait :one_time do
      billing_type { :one_time }
      frequency    { :monthly }
      access_expires_at { 30.days.from_now }
      external_id  { nil }
      external_customer_id { nil }
      external_plan_id { nil }
      mp_preference_id { "mp_pref_#{SecureRandom.hex(8)}" }
    end

    trait :past_due do
      status { :past_due }
    end

    trait :past_due_with_since do
      status { :past_due }
      past_due_since { Time.current }
    end

    trait :canceled do
      status    { :canceled }
      canceled_at { Time.current }
    end
  end
end
