FactoryBot.define do
  factory :user_dietary_plan do
    association :user
    association :dietary_plan
    calories_target { 2000 }
    protein_target { 150 }
    active { true }
  end
end
