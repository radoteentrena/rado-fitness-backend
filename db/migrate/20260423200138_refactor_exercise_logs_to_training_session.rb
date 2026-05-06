class RefactorExerciseLogsToTrainingSession < ActiveRecord::Migration[8.0]
  def up
    add_reference :exercise_logs, :training_session, null: true, foreign_key: true

    execute <<~SQL
      UPDATE exercise_logs
      SET training_session_id = program_executions.training_session_id
      FROM program_executions
      WHERE program_executions.id = exercise_logs.program_execution_id
    SQL

    execute "DELETE FROM exercise_logs WHERE training_session_id IS NULL"

    change_column_null :exercise_logs, :training_session_id, false

    remove_foreign_key :exercise_logs, :program_executions
    remove_reference :exercise_logs, :program_execution, null: false, foreign_key: false

    drop_table :program_executions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
