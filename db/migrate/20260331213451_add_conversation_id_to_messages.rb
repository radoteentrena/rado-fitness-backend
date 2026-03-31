class AddConversationIdToMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :messages, :conversation, foreign_key: true, null: true
    add_index :messages, [:conversation_id, :created_at]
  end
end
