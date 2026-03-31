class MigrateMessagesToConversations < ActiveRecord::Migration[8.0]
  def up
    # For each unique user with messages, create a conversation and assign messages to it
    Message.select(:user_id).distinct.pluck(:user_id).each do |user_id|
      conversation = Conversation.find_or_create_by(user_id: user_id)
      Message.where(user_id: user_id, conversation_id: nil).update_all(conversation_id: conversation.id)
    end
  end

  def down
    # Not reversible — this is a data migration
    raise ActiveRecord::IrreversibleMigration
  end
end
