class AiCoachGenerationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, mode: "program", gender: nil, focus: nil, level: nil)
    conversation = AiConversation.find(conversation_id)

    result = AiCoachService.new.generate_program(
      objectives:   conversation.objectives,
      user:         conversation.user,
      mode:         mode,
      gender:       gender,
      focus:        focus,
      level:        level,
      conversation: conversation
    )

    if result[:structured_data].blank?
      conversation.update(status: "failed")
      broadcast_error(conversation, "La IA no generó un formato válido. Ajustá el prompt e intentá de nuevo.")
    else
      conversation.update!(status: "ready")
      broadcast_result(conversation, result[:structured_data])
    end
  rescue StandardError => e
    Rails.logger.error("AiCoachGenerationJob error (conversation #{conversation_id}): #{e.message}")
    conversation&.update(status: "failed")
    broadcast_error(conversation, "Error generando el programa: #{e.message}") if conversation
  end

  private

  def broadcast_result(conversation, structured_data)
    Turbo::StreamsChannel.broadcast_replace_to(
      conversation,
      target:  "ai_coach_result",
      partial: "admin/ai_coach/result",
      locals:  { conversation: conversation, structured_data: structured_data }
    )
  end

  def broadcast_error(conversation, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      conversation,
      target:  "ai_coach_result",
      partial: "admin/ai_coach/generation_error",
      locals:  { message: message }
    )
  end
end
