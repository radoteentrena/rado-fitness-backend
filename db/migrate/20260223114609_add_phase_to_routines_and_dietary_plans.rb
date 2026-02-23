class AddPhaseToRoutinesAndDietaryPlans < ActiveRecord::Migration[8.0]
  def change
    add_reference :routines, :phase, null: true, foreign_key: true
    add_reference :user_dietary_plans, :phase, null: true, foreign_key: true
  end
end
