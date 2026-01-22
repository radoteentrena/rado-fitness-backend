class RenameRoutineItemsToRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    rename_table :routine_items, :routine_exercises
  end
end
