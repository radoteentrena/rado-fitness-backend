FactoryBot.define do
  factory :phase_routine do
    association :phase
    association :routine
    order_index { 1 }
  end
end
