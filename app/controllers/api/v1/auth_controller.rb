class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:google, :email]
  skip_before_action :check_access_locked!, only: [:destroy]

  # POST /api/v1/auth/google
  def google
    id_token = params.require(:id_token)

    begin
      payload = GoogleSignIn::Identity.new(id_token).payload
    rescue StandardError => e
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    email = payload['email']&.downcase

    unless email
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    user = User.find_by(email: email, status: :active)

    unless user
      return render json: { error: "No active account found with this email" }, status: :unauthorized
    end

    user.update(google_uid: payload['sub'], provider: 'google_oauth2') unless user.google_uid.present?

    render json: {
      auth_token: user.auth_token,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        plan_tier: user.plan_tier,
        avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil
      }
    }, status: :ok
  end

  # DELETE /api/v1/auth/session
  def destroy
    current_user.regenerate_auth_token
    head :no_content
  end

  # POST /api/v1/auth/email
  def email
    email    = params.require(:email).downcase.strip
    password = params.require(:password)

    user = User.find_by(email: email, status: :active)

    unless user&.valid_password?(password)
      return render json: { error: "Invalid email or password" }, status: :unauthorized
    end

    render json: {
      auth_token: user.auth_token,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        plan_tier: user.plan_tier,
        avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil
      }
    }, status: :ok
  end
end
