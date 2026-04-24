class AddUniqueIndexToExerciseLogs < ActiveRecord::Migration[8.0]
  def change
    add_index :exercise_logs, [:training_session_id, :workout_exercise_id], unique: true, name: "index_exercise_logs_unique_per_session"
  end
end
