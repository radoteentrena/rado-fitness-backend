class Exercise < ApplicationRecord
  MUSCLE_GROUPS = [
    "Pecho", "Espalda", "Hombros", "Bíceps", "Tríceps",
    "Cuádriceps", "Isquiotibiales", "Glúteos", "Pantorrillas",
    "Core", "Trapecio", "Full Body"
  ].freeze

  has_many :workout_exercises
  has_many :workouts, through: :workout_exercises

  validates :name, presence: true
end
