class NotifyUserOfCoachReplyJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    conversation = message.conversation
    user = conversation.user

    return if message.sender_type == "client"

    begin
      PushNotification.new(
        user: user,
        title: "Respuesta de Rado",
        body: message.content&.truncate(100) || "Mensaje de voz",
        data: { type: "coach_reply", conversation_id: message.conversation_id.to_s }
      ).deliver
    rescue StandardError => e
      Rails.logger.error("Failed to send push notification: #{e.message}")
    end

    Notification.create!(
      conversation: conversation,
      notification_type: "coach_reply",
      message: "Rado respondió tu pregunta"
    )
  end
end
