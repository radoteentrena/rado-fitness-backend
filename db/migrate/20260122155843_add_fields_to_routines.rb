class AddFieldsToRoutines < ActiveRecord::Migration[8.0]
  def change
    add_column :routines, :duration_weeks, :integer
  end
end
