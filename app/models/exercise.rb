class Exercise < ApplicationRecord
  MUSCLE_GROUPS = [
    "Pecho", "Espalda", "Hombros", "Trapecio",
    "Bíceps", "Tríceps", "Antebrazos", "Brazos",
    "Cuádriceps", "Isquiotibiales", "Glúteos", "Pantorrillas",
    "Piernas", "Abductores", "Aductores",
    "Core", "Full Body"
  ].freeze

  # Cache of the exercise library handed to the AI coach (see AiCoachService).
  # The AI may only pick from this list, so it must be busted on any change or a
  # newly added exercise stays invisible (and gets reported as skipped).
  AI_LIST_CACHE_KEY = "exercises_list_v2".freeze

  has_many :workout_exercises, dependent: :destroy
  has_many :workouts, through: :workout_exercises

  validates :name, presence: true

  after_commit -> { Rails.cache.delete(AI_LIST_CACHE_KEY) }
end
