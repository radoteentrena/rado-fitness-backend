class CreateUserDietaryPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :user_dietary_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :calories_target
      t.integer :protein_target
      t.text :notes

      t.timestamps
    end
  end
end
