class CreatePhaseRoutines < ActiveRecord::Migration[8.0]
  def change
    create_table :phase_routines do |t|
      t.references :phase, null: false, foreign_key: true
      t.references :routine, null: false, foreign_key: true
      t.integer :order_index

      t.timestamps
    end
  end
end
