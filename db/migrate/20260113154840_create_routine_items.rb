class CreateRoutineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :routine_items do |t|
      t.references :routine, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :sets
      t.string :reps
      t.string :rir
      t.integer :rest_seconds
      t.integer :order_index

      t.timestamps
    end
  end
end
