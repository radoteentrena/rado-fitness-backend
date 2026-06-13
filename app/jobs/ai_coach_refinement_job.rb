class AiCoachRefinementJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, message)
    conversation = AiConversation.find(conversation_id)

    result = AiCoachService.new.refine(conversation: conversation, message: message)

    if result[:structured_data].blank?
      broadcast_error(conversation, "La IA no devolvió cambios válidos. Reformulá tu pedido e intentá de nuevo.")
    else
      Turbo::StreamsChannel.broadcast_replace_to(
        conversation,
        target:  "ai_coach_result",
        partial: "admin/ai_coach/result",
        locals:  { conversation: conversation, structured_data: result[:structured_data] }
      )
    end
  rescue StandardError => e
    Rails.logger.error("AiCoachRefinementJob error (conversation #{conversation_id}): #{e.message}")
    broadcast_error(conversation, "Error refinando el programa: #{e.message}") if conversation
  end

  private

  def broadcast_error(conversation, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      conversation,
      target:  "ai_coach_result",
      partial: "admin/ai_coach/generation_error",
      locals:  { message: message }
    )
  end
end
