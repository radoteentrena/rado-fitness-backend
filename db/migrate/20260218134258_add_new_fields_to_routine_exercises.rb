class AddNewFieldsToRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :routine_exercises, :intensity_technique, :string
    add_column :routine_exercises, :rest, :string
  end
end
