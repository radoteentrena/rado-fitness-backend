class Workout < ApplicationRecord
  belongs_to :routine
  has_many :workout_exercises, dependent: :destroy
  has_many :program_executions, dependent: :destroy
end
