class CreateProgramExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :program_executions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :routine, null: false, foreign_key: true
      t.datetime :completed_at
      t.integer :duration_minutes

      t.timestamps
    end
  end
end
