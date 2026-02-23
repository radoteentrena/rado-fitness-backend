class CreatePhases < ActiveRecord::Migration[8.0]
  def change
    create_table :phases do |t|
      t.references :program, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :order_index
      t.integer :duration_weeks

      t.timestamps
    end
  end
end
