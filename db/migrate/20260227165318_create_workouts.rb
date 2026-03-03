class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.string :name
      t.text :description
      t.integer :day_number
      t.integer :order_index
      t.references :routine, null: false, foreign_key: true

      t.timestamps
    end
  end
end
