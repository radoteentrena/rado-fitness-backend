class DietaryPlan < ApplicationRecord
  has_many :user_dietary_plans, dependent: :nullify

  validates :name, presence: true
  validates :calories_target, :protein_target, presence: true

  # Picks the existing template whose calorie target is closest to `target`.
  def self.closest_to_calories(target)
    return nil if target.nil?

    where.not(calories_target: nil).min_by { |plan| (plan.calories_target - target).abs }
  end

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
        fats_target: fats_target,
        carbs_target: carbs_target,
        notes: notes,
        start_date: Date.current,
        active: true
      )
    end
  end
end
