class Routine < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :program, optional: true
  has_many :routine_exercises, dependent: :destroy
  has_many :exercises, through: :routine_exercises

  scope :templates, -> { where(is_template: true) }

  def clone_to_user(target_user)
    transaction do
      new_routine = dup
      new_routine.is_template = false
      new_routine.user = target_user
      new_routine.name = "#{name} (Copy)"
      new_routine.save!

      routine_exercises.each do |item|
        new_item = item.dup
        new_item.routine = new_routine
        new_item.save!
      end

      new_routine
    end
  end

  validates :name, presence: true
end
