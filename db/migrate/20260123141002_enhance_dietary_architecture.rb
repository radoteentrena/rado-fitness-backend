class EnhanceDietaryArchitecture < ActiveRecord::Migration[8.0]
  def change
    add_column :dietary_plans, :calories_target, :integer
    add_column :dietary_plans, :protein_target, :integer
    add_column :dietary_plans, :notes, :text

    add_reference :user_dietary_plans, :dietary_plan, foreign_key: true, null: true
    add_column :user_dietary_plans, :start_date, :date
    add_column :user_dietary_plans, :end_date, :date
    add_column :user_dietary_plans, :active, :boolean, default: true
    add_reference :daily_metrics, :user_dietary_plan, foreign_key: true, null: true
  end
end
