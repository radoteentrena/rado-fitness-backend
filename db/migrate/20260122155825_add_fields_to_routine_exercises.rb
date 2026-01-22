class AddFieldsToRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :routine_exercises, :day_number, :integer
    add_column :routine_exercises, :day_name, :string
    add_column :routine_exercises, :warmup, :boolean
    add_column :routine_exercises, :load, :string
    add_column :routine_exercises, :sub_option, :integer
    add_column :routine_exercises, :instructions, :text
  end
end
