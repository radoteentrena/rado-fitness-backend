class NotifyCoachOfNewMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    conversation = message.conversation
    user = conversation.user

    # Skip if message is from coach (self-message)
    return if message.sender_type == 'coach'

    # Send notification to admin/coach
    notify_admin(user, message)

    # Track the notification
    Notification.create!(
      conversation: conversation,
      notification_type: 'new_message',
      message: "#{user.first_name} #{user.last_name} te envió un mensaje"
    )
  end

  private

  def notify_admin(user, message)
    # Firebase FCM or web notification to admin
    # For now, this is a stub. In production, integrate with FCM or WebSocket
    AdminNotification.notify(
      title: "Nuevo mensaje de #{user.first_name}",
      body: message.content&.truncate(100) || "Mensaje de voz",
      action_url: "/admin/conversations/#{message.conversation.id}"
    )
  end
end
