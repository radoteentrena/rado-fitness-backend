FactoryBot.define do
  factory :dietary_plan do
    sequence(:name) { |n| "Dietary Plan #{n}" }
    calories_target { 2000 }
    protein_target { 150 }
  end
end
