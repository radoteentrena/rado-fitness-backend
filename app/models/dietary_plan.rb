class DietaryPlan < ApplicationRecord
  has_many :user_dietary_plans, dependent: :nullify

  validates :name, presence: true
  validates :calories_target, :protein_target, presence: true

  def assign_to_user(target_user)
    transaction do
      # Deactivate existing plans
      target_user.user_dietary_plans.update_all(active: false)

      # Create new plan
      UserDietaryPlan.create!(
        user: target_user,
        dietary_plan: self,
        calories_target: calories_target,
        protein_target: protein_target,
        notes: notes,
        start_date: Date.current,
        active: true
      )
    end
  end
end
