class CreateExerciseLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_logs do |t|
      t.references :program_execution, null: false, foreign_key: true
      t.references :routine_exercise, null: false, foreign_key: true
      t.jsonb :actual_sets

      t.timestamps
    end
  end
end
