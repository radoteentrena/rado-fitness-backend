FactoryBot.define do
  factory :program do
    sequence(:name) { |n| "Program #{n}" }
    duration_weeks { 12 }
  end
end
