class Api::V1::MessagesController < Api::V1::BaseController
  before_action :check_messaging_tier

  def index
    @conversation = current_user.conversations.find_or_create_by(user_id: current_user.id)
    @messages = @conversation.messages.not_deleted.chronological

    Message.where(conversation: @conversation, sender_type: :coach, read_at: nil).update_all(read_at: Time.current)

    render json: {
      conversation: serialize_conversation(@conversation),
      messages: serialize_messages(@messages)
    }
  end

  def create
    @conversation = current_user.conversations.find_or_create_by(user_id: current_user.id)
    @message = @conversation.messages.build(message_params)
    @message.user = current_user
    @message.sender_type = :client

    if @message.save
      @conversation.update(last_message_at: Time.current)

      NotifyCoachOfNewMessageJob.perform_later(@message.id) if defined?(NotifyCoachOfNewMessageJob)

      render json: serialize_message(@message), status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def check_messaging_tier
    return if current_user.medium? || current_user.high_ticket?
    render json: { error: 'Plan does not include messaging' }, status: :unauthorized
  end

  def message_params
    params.require(:message).permit(:content, :voice_note)
  end

  def serialize_conversation(conversation)
    {
      id: conversation.id,
      user_id: conversation.user_id,
      last_message_at: conversation.last_message_at,
      read_by_coach_at: conversation.read_by_coach_at
    }
  end

  def serialize_messages(messages)
    messages.map { |m| serialize_message(m) }
  end

  def serialize_message(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_type: message.sender_type.to_s,
      content: message.content,
      voice_note_url: message.voice_note.attached? ? url_for(message.voice_note) : nil,
      read_at: message.read_at,
      created_at: message.created_at
    }
  end
end
