class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include Rails.application.routes.url_helpers

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
    render json: { error: "access_locked", payment_url: subscription_payment_url }, status: :forbidden
  end

  def subscription_payment_url
    host = Rails.application.credentials.dig(:app_host)
    return new_subscription_url(host: host, protocol: :https) if host.present?

    Rails.logger.warn "app_host credential missing — returning relative payment path in access_locked response"
    new_subscription_path
  end

  def default_url_options
    { host: Rails.application.credentials.dig(:app_host) }
  end
end
