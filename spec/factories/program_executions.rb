FactoryBot.define do
  factory :program_execution do
    association :user
    association :workout
    completed_at { Time.current }
  end
end
