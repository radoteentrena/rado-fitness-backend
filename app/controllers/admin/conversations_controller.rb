module Admin
  class ConversationsController < Admin::ApplicationController
    before_action :set_conversation, only: [:show, :create_message, :delete_message]
    before_action :load_conversations, only: [:index, :show]

    layout :resolve_layout

    def index
    end

    def show
      @conversation.update(read_by_coach_at: Time.current)
      @messages = @conversation.messages.not_deleted.chronological
      @message = Message.new
    end

    def create_message
      @message = @conversation.messages.build(message_params)
      @message.user_id = @conversation.user_id
      @message.sender_type = :coach

      if params[:voice_data].present?
        voice_io = decode_base64_to_blob(params[:voice_data])
        @message.voice_note.attach(voice_io) if voice_io
      end

      if @message.save
        @conversation.update(last_message_at: Time.current)

        NotifyUserOfCoachReplyJob.perform_later(@message.id)

        redirect_to admin_conversation_path(@conversation), notice: t('admin.conversations.message_sent')
      else
        redirect_to admin_conversation_path(@conversation), alert: "#{t('admin.conversations.error_sending_message')}: #{@message.errors.full_messages.join(', ')}"
      end
    end

    def delete_message
      @message = @conversation.messages.find(params[:message_id])

      if @message.coach?
        @message.discard
        redirect_to admin_conversation_path(@conversation), notice: t('admin.conversations.message_deleted')
      else
        redirect_to admin_conversation_path(@conversation), alert: t('admin.conversations.cannot_delete_client_message')
      end
    end

    private

    def resolve_layout
      case action_name
      when 'index'
        'conversations'
      when 'show'
        request.headers['turbo-frame'] == 'conversation-detail' ? false : 'conversations'
      else
        nil
      end
    end

    def set_conversation
      conversation_id = params[:id] || params[:conversation_id]
      @conversation = Conversation.find(conversation_id)
    end

    def load_conversations
      @conversations = Conversation
        .left_joins(:messages)
        .preload(:user)
        .select(
          "conversations.*",
          "COUNT(CASE WHEN messages.read_at IS NULL AND messages.sender_type = 'client' AND messages.discarded_at IS NULL THEN 1 END) AS unread_count"
        )
        .group("conversations.id")
        .order(Arel.sql("unread_count DESC, COALESCE(conversations.last_message_at, '1970-01-01') DESC"))
    end

    def message_params
      params.require(:conversation).permit(:content)
    end

    def decode_base64_to_blob(data_url)
      return nil unless data_url.is_a?(String) && data_url.include?(',')

      base64_data = data_url.split(',')[1]
      return nil unless base64_data

      binary_data = Base64.decode64(base64_data)
      filename = "voice_#{Time.current.to_i}.webm"

      tempfile = Tempfile.new([filename.gsub(/\.webm$/, ''), '.webm'], encoding: 'ASCII-8BIT')
      tempfile.binmode
      tempfile.write(binary_data)
      tempfile.rewind

      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: filename,
        type: "audio/webm"
      )
    end
  end
end
