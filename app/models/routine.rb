class Routine < ApplicationRecord
  belongs_to :user, optional: true
  has_many :phase_routines, dependent: :destroy
  has_many :phases, through: :phase_routines
  has_many :workouts, dependent: :destroy
  has_many :workout_exercises, through: :workouts
  has_many :exercises, through: :workout_exercises

  before_destroy :prevent_deletion_if_assigned_to_user

  FOCUSES = ["Fuerza", "Estética", "Salud", "Atletismo"].freeze
  LEVELS  = ["Principiante", "Intermedio", "Avanzado"].freeze
  GENDERS = ["Hombre", "Mujer"].freeze

  scope :templates, -> { where(is_template: true) }

  def clone_to_user(target_user)
    transaction do
      new_routine = dup
      new_routine.is_template = false
      new_routine.user = target_user
      new_routine.name = "#{name} (Copy)"
      new_routine.save!

      workouts.each do |workout|
        new_workout = workout.dup
        new_workout.routine = new_routine
        new_workout.save!

        workout.workout_exercises.each do |item|
          new_item = item.dup
          new_item.workout = new_workout
          new_item.save!
        end
      end

      new_routine
    end
  end

  validates :name, presence: true

  private

  def prevent_deletion_if_assigned_to_user
    if user_id.present?
      errors.add(:base, "Cannot delete a routine assigned to a user. Unassign it first.")
      throw(:abort)
    end
  end
end
