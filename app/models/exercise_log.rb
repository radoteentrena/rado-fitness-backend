class ExerciseLog < ApplicationRecord
  belongs_to :program_execution
  belongs_to :routine_exercise
end
