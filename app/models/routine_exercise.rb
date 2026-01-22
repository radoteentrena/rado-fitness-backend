class RoutineExercise < ApplicationRecord
  belongs_to :routine
  belongs_to :exercise

  validates :sets, :reps, presence: true
end
