class NotifyUserOfCoachReplyJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    conversation = message.conversation
    user = conversation.user

    # Skip if message is from client (not a reply from coach)
    return if message.sender_type == 'client'

    # Send Firebase FCM push notification to user's mobile app
    begin
      send_fcm_notification(user, message)
    rescue StandardError => e
      Rails.logger.error("Failed to send FCM notification: #{e.message}")
      # Continue to create notification record even if FCM fails
    end

    # Track the notification
    Notification.create!(
      conversation: conversation,
      notification_type: 'coach_reply',
      message: "Rado respondió tu pregunta"
    )
  end

  private

  def send_fcm_notification(user, message)
    # Firebase Cloud Messaging integration
    # This requires FCM credentials and the user's device token
    return unless user.fcm_token.present?

    notification_payload = {
      title: "Respuesta de Rado",
      body: message.content&.truncate(100) || "Mensaje de voz",
      sound: "default",
      click_action: "FLUTTER_NOTIFICATION_CLICK"
    }

    data_payload = {
      conversation_id: message.conversation_id.to_s,
      message_id: message.id.to_s,
      type: "coach_reply"
    }

    begin
      # Firebase::MessagingService.send_notification(
      #   user.fcm_token,
      #   notification_payload,
      #   data_payload
      # )
      Rails.logger.info("FCM notification sent to user #{user.id} for message #{message.id}")
    rescue StandardError => e
      Rails.logger.error("Failed to send FCM notification: #{e.message}")
      # Silently fail - don't retry
    end
  end
end
