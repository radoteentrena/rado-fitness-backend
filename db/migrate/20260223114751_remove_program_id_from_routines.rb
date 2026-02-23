class RemoveProgramIdFromRoutines < ActiveRecord::Migration[8.0]
  def change
    remove_reference :routines, :program, foreign_key: true
  end
end
