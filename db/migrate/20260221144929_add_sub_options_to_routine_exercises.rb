class AddSubOptionsToRoutineExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :routine_exercises, :sub_option_one, :string
    add_column :routine_exercises, :sub_option_two, :string
  end
end
