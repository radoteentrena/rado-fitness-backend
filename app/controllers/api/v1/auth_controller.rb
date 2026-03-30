class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:google]

  # POST /api/v1/auth/google
  # Authenticates user via Google ID token
  def google
    # Extract and validate token
    id_token = params.require(:id_token)

    begin
      # Validate token with Google's public keys
      payload = GoogleSignIn::Identity.new(id_token).payload
    rescue StandardError => e
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    # Extract email from validated token
    email = payload['email']&.downcase

    unless email
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    # Find user: must exist and be active
    user = User.find_by(email: email, status: :active)

    unless user
      return render json: { error: "No active account found with this email" }, status: :unauthorized
    end

    # Update google_uid if not already set
    user.update(google_uid: payload['sub'], provider: 'google_oauth2') unless user.google_uid.present?

    # Return auth token and user data
    render json: {
      auth_token: user.auth_token,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        plan_tier: user.plan_tier
      }
    }, status: :ok
  end
end
