class AddProgramToRoutines < ActiveRecord::Migration[8.0]
  def change
    add_reference :routines, :program, null: true, foreign_key: true
  end
end
