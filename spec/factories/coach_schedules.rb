FactoryBot.define do
  factory :coach_schedule do
    sequence(:day_of_week) { |n| n % 7 }
    start_hour { 9 }
    end_hour { 18 }
    active { true }
  end
end
