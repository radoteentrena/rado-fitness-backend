module Admin
  class ConversationsController < Admin::ApplicationController
    before_action :set_conversation, only: [:show, :create_message, :delete_message]

    def show
      # Update read_by_coach_at when Rado opens conversation
      @conversation.update(read_by_coach_at: Time.current)
      @messages = @conversation.messages.not_deleted.chronological
      @message = Message.new
    end

    def create_message
      @message = @conversation.messages.build(message_params)
      @message.user_id = @conversation.user_id
      @message.sender_type = :coach

      # Handle voice note from base64 data URL
      if params[:voice_data].present?
        voice_io = decode_base64_to_blob(params[:voice_data])
        @message.voice_note.attach(voice_io) if voice_io
      end

      if @message.save
        @conversation.update(last_message_at: Time.current)

        # Trigger notification to user (defer to background job)
        NotifyUserOfCoachReplyJob.perform_later(@message.id) if defined?(NotifyUserOfCoachReplyJob)

        redirect_to admin_conversation_path(@conversation), notice: t('admin.conversations.message_sent')
      else
        redirect_to admin_conversation_path(@conversation), alert: "#{t('admin.conversations.error_sending_message')}: #{@message.errors.full_messages.join(', ')}"
      end
    end

    def delete_message
      @message = @conversation.messages.find(params[:message_id])

      # Only coach can delete messages, and only their own
      if @message.coach?
        @message.discard
        redirect_to admin_conversation_path(@conversation), notice: t('admin.conversations.message_deleted')
      else
        redirect_to admin_conversation_path(@conversation), alert: t('admin.conversations.cannot_delete_client_message')
      end
    end

    private

    def set_conversation
      # Handle both :id (from show) and :conversation_id (from nested routes)
      conversation_id = params[:id] || params[:conversation_id]
      @conversation = Conversation.find(conversation_id)
    end

    def message_params
      params.permit(:content)
    end

    def decode_base64_to_blob(data_url)
      # Extract base64 from data URL like "data:audio/webm;base64,xxxxx"
      return nil unless data_url.is_a?(String) && data_url.include?(',')

      base64_data = data_url.split(',')[1]
      return nil unless base64_data

      binary_data = Base64.decode64(base64_data)
      filename = "voice_#{Time.current.to_i}.webm"

      # Create an UploadedFile that ActionController expects
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new,
        filename: filename,
        type: "audio/webm"
      ).tap { |file| file.tempfile.write(binary_data) && file.tempfile.rewind }
    end
  end
end
