class CreateCoachSchedules < ActiveRecord::Migration[8.0]
  def up
    create_table :coach_schedules do |t|
      t.integer :day_of_week, null: false
      t.integer :start_hour, null: false, default: 9
      t.integer :end_hour, null: false, default: 18
      t.boolean :active, null: false, default: false
      t.timestamps
    end

    add_index :coach_schedules, :day_of_week, unique: true

    # Seed default Mon–Fri schedule (Buenos Aires time)
    # 0=Sunday, 1=Monday, ..., 6=Saturday
    [
      [0, false], [1, true], [2, true], [3, true],
      [4, true],  [5, true], [6, false]
    ].each do |day, active|
      execute <<~SQL
        INSERT INTO coach_schedules (day_of_week, start_hour, end_hour, active, created_at, updated_at)
        VALUES (#{day}, 9, 18, #{active}, NOW(), NOW())
      SQL
    end
  end

  def down
    drop_table :coach_schedules
  end
end
