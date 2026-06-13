class AddWorkoutsCountToRoutines < ActiveRecord::Migration[8.0]
  def up
    add_column :routines, :workouts_count, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE routines
      SET workouts_count = (
        SELECT COUNT(*) FROM workouts WHERE workouts.routine_id = routines.id
      )
    SQL
  end

  def down
    remove_column :routines, :workouts_count
  end
end
