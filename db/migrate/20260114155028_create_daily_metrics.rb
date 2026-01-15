class CreateDailyMetrics < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_metrics do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date_logged
      t.integer :calories_consumed
      t.integer :protein_consumed
      t.integer :steps
      t.float :weight
      t.text :raw_message_content
      t.boolean :compliant
      t.jsonb :ai_parsed_json

      t.timestamps
    end
  end
end
