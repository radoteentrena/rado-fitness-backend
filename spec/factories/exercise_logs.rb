FactoryBot.define do
  factory :exercise_log do
    association :program_execution
    association :workout_exercise
    actual_sets { [{ "reps" => 8, "weight" => 100, "rpe" => 7 }] }
  end
end
