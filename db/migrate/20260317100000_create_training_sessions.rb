class CreateTrainingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :training_sessions do |t|
      t.bigint :user_id, null: false
      t.bigint :program_id, null: false
      t.bigint :phase_id, null: false
      t.bigint :routine_id, null: false
      t.bigint :workout_id, null: false

      t.integer :cycle_number, null: false
      t.integer :session_number, null: false

      t.integer :status, null: false, default: 0

      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :skipped_at

      t.string :skip_reason
      t.text :notes

      t.timestamps
    end

    add_index :training_sessions, [ :user_id, :status ]
    add_index :training_sessions, [ :user_id, :session_number ]
    add_index :training_sessions, :workout_id
    add_index :training_sessions, :phase_id
    add_index :training_sessions, :program_id

    add_foreign_key :training_sessions, :users
    add_foreign_key :training_sessions, :programs
    add_foreign_key :training_sessions, :phases
    add_foreign_key :training_sessions, :routines
    add_foreign_key :training_sessions, :workouts
  end
end
