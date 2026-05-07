class AddUniqueIndexToExercisesName < ActiveRecord::Migration[8.0]
  def up
    # Remove duplicate exercise names before adding constraint, keeping the oldest record
    execute <<~SQL
      DELETE FROM exercises
      WHERE id NOT IN (
        SELECT MIN(id) FROM exercises GROUP BY LOWER(name)
      )
    SQL

    add_index :exercises, :name, unique: true, name: "index_exercises_on_name_unique"
  end

  def down
    remove_index :exercises, name: "index_exercises_on_name_unique"
  end
end
