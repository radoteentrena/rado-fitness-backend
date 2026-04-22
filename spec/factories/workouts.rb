FactoryBot.define do
  factory :workout do
    association :routine
    sequence(:name) { |n| "Workout #{n}" }
    day_number { 1 }
    order_index { 1 }
  end
end
