FactoryBot.define do
  factory :phase do
    association :program
    sequence(:name) { |n| "Phase #{n}" }
    order_index { 1 }
    duration_weeks { 4 }
  end
end
