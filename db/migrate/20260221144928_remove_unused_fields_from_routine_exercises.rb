class RemoveUnusedFieldsFromRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    remove_column :routine_exercises, :rir, :string
    remove_column :routine_exercises, :warmup, :boolean
    remove_column :routine_exercises, :sub_option, :integer
    remove_column :routine_exercises, :instructions, :text
    remove_column :routine_exercises, :substitutions, :jsonb
    remove_column :routine_exercises, :rest, :string
  end
end
