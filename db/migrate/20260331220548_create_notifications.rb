class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :notification_type
      t.text :message

      t.timestamps
    end
  end
end
