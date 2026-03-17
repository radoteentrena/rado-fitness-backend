class AddTrainingSessionIdToProgramExecutions < ActiveRecord::Migration[8.0]
  def change
    add_column :program_executions, :training_session_id, :bigint
    add_index :program_executions, :training_session_id
    add_foreign_key :program_executions, :training_sessions
  end
end
