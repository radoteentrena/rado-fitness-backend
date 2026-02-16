class AddDetailedFieldsToRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :routine_exercises, :warmup_sets, :string
    add_column :routine_exercises, :early_rpe, :string
    add_column :routine_exercises, :last_rpe, :string
    add_column :routine_exercises, :time_estimate, :string
    add_column :routine_exercises, :substitutions, :jsonb
  end
end
