class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user!
  before_action :check_access_locked!

  private

  def authenticate_user!
    authenticate_or_request_with_http_token do |token, options|
      @current_user = User.find_by(auth_token: token)
    end
  end

  def current_user
    @current_user
  end

  def check_access_locked!
    return unless current_user&.access_locked?
    render json: { error: "access_locked", payment_path: "/subscription/new" }, status: :forbidden
  end
end
