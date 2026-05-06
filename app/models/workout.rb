class Workout < ApplicationRecord
  belongs_to :routine
  has_many :workout_exercises, dependent: :destroy
end
