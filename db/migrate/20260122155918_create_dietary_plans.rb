class CreateDietaryPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :dietary_plans do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
