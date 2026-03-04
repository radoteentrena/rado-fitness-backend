class ExerciseLog < ApplicationRecord
  belongs_to :program_execution
  belongs_to :workout_exercise
end
