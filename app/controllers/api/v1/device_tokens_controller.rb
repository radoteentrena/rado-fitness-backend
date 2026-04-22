class Api::V1::DeviceTokensController < Api::V1::BaseController
  def update
    if params[:fcm_token].blank?
      render json: { error: "Invalid fcm_token" }, status: :unprocessable_entity
    elsif current_user.update(fcm_token: params[:fcm_token])
      head :no_content
    else
      render json: { error: "Invalid fcm_token" }, status: :unprocessable_entity
    end
  end
end
