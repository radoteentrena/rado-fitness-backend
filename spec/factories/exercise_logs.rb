FactoryBot.define do
  factory :exercise_log do
    association :training_session
    association :workout_exercise
    actual_sets { [{ "reps" => 8, "weight" => 100, "rpe" => 7 }] }
  end
end
