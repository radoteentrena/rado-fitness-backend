class WorkoutExercise < ApplicationRecord
  INTENSITY_TECHNIQUES = [
    "Drop Set",
    "Parciales en estiramiento",
    "Myo-Reps",
    "Rest-Pause",
    "Super Serie",
    "Serie Gigante",
    "Cluster Set",
    "1.5 Repeticiones",
    "Énfasis excéntrico",
    "Pre-Agotamiento",
    "Drop Set Mecánico",
    "AMRAP"
  ].freeze

  belongs_to :workout
  belongs_to :exercise

  validates :sets, :reps, presence: true
end
