FactoryBot.define do
  factory :workout_exercise do
    association :workout
    association :exercise
    sets { 4 }
    reps { "8-10" }
    order_index { 1 }
  end
end
