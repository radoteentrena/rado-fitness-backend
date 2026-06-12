FactoryBot.define do
  factory :user_dietary_plan do
    association :user
    calories_target { 2000 }
    protein_target { 150 }
    fats_target { 67 }
    carbs_target { 200 }
    start_date { Date.current }
    active { true }
  end
end
