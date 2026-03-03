class MigrateRoutineExercisesToWorkouts < ActiveRecord::Migration[8.0]
  class Routine < ApplicationRecord
    has_many :routine_exercises
  end
  class RoutineExercise < ApplicationRecord
    has_many :exercise_logs
  end
  class Workout < ApplicationRecord
  end
  class ProgramExecution < ApplicationRecord
    has_many :exercise_logs
  end
  class ExerciseLog < ApplicationRecord
    belongs_to :routine_exercise
    belongs_to :program_execution
  end

  def up
    # 1. Add workout_id to routine_exercises (nullable for now)
    add_reference :routine_exercises, :workout, foreign_key: true

    # 2. Migrate data from Routine/RoutineExercise to Workout
    Routine.find_each do |routine|
      # Group exercises by day_number (fallback to 1)
      grouped_exercises = routine.routine_exercises.group_by { |ex| ex.day_number || 1 }

      grouped_exercises.each do |day_number, exercises|
        day_name = exercises.map(&:day_name).compact.first || "Day #{day_number}"

        workout = Workout.create!(
          routine_id: routine.id,
          name: day_name,
          day_number: day_number,
          order_index: day_number
        )

        # Link exercises to the new workout
        exercises.each_with_index do |ex, idx|
          ex.update_columns(workout_id: workout.id, order_index: (ex.order_index || idx))
        end
      end
    end

    # Clean orphans
    RoutineExercise.where(workout_id: nil).delete_all

    # 3. Add workout_id to program_executions
    add_reference :program_executions, :workout, foreign_key: true

    # 4. Migrate program_executions
    ProgramExecution.find_each do |pe|
      first_log = pe.exercise_logs.first
      workout_id = nil
      if first_log && first_log.routine_exercise
        workout_id = first_log.routine_exercise.workout_id
      else
        first_workout = Workout.find_by(routine_id: pe.routine_id)
        workout_id = first_workout&.id
      end
      pe.update_columns(workout_id: workout_id) if workout_id
    end

    ProgramExecution.where(workout_id: nil).delete_all

    # 5. Clean up old references and columns
    # Program Executions Cleanup
    remove_reference :program_executions, :routine, foreign_key: true
    change_column_null :program_executions, :workout_id, false

    # Routine Exercises Cleanup
    remove_reference :routine_exercises, :routine, foreign_key: true
    remove_column :routine_exercises, :day_number, :integer
    remove_column :routine_exercises, :day_name, :string
    change_column_null :routine_exercises, :workout_id, false

    # 6. Rename tables/columns
    rename_table :routine_exercises, :workout_exercises
    rename_column :exercise_logs, :routine_exercise_id, :workout_exercise_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert Workout extraction."
  end
end
