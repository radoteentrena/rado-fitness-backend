class Api::V1::DeviceTokensController < Api::V1::BaseController
  def update
    if token_params[:fcm_token].blank?
      render json: { errors: ["fcm_token can't be blank"] }, status: :unprocessable_entity
    elsif current_user.update(fcm_token: token_params[:fcm_token])
      head :no_content
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def token_params
    params.permit(:fcm_token)
  end
end
