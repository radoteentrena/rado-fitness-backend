class CreateAiConversationsAndMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_conversations do |t|
      t.references :user, foreign_key: true, null: true
      t.string :title
      t.text :objectives
      t.string :status, default: "active"
      t.jsonb :generated_data
      t.references :program, foreign_key: true, null: true
      t.timestamps
    end

    create_table :ai_messages do |t|
      t.references :ai_conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :structured_data
      t.timestamps
    end
  end
end
