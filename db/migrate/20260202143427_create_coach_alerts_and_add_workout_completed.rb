class CreateCoachAlertsAndAddWorkoutCompleted < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false # missed_workout, low_compliance, etc
      t.text :message
      t.integer :status, default: 0 # pending
      t.text :action_taken

      t.timestamps
    end

    add_column :daily_metrics, :workout_completed, :boolean, default: false
  end
end
