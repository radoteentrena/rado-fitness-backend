class AddFatsAndCarbsTargetToDietaryPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :dietary_plans, :fats_target, :integer
    add_column :dietary_plans, :carbs_target, :integer
    add_column :user_dietary_plans, :fats_target, :integer
    add_column :user_dietary_plans, :carbs_target, :integer
  end
end
