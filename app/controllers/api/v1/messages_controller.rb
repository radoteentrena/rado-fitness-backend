class Api::V1::MessagesController < Api::V1::BaseController
  def index
    @messages = current_user.messages.order(created_at: :desc).limit(50)
  end

  def create
    @message = current_user.messages.build(message_params)
    @message.sender_type = "user"

    if @message.save
      render "api/v1/messages/show", status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
