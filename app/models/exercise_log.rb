class ExerciseLog < ApplicationRecord
  belongs_to :training_session
  belongs_to :workout_exercise, optional: true
end
