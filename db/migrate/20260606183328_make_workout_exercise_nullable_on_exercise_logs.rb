class MakeWorkoutExerciseNullableOnExerciseLogs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :exercise_logs, :workout_exercise_id, true
  end
end
