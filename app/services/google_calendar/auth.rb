module GoogleCalendar
  class Auth
    SCOPES = %w[
      https://www.googleapis.com/auth/calendar.events
      https://www.googleapis.com/auth/calendar.freebusy
    ].freeze

    AUTHORIZATION_URI   = "https://accounts.google.com/o/oauth2/auth"
    TOKEN_URI           = "https://oauth2.googleapis.com/token"

    def self.authorization_url
      build_client.authorization_uri(
        additional_parameters: { access_type: "offline", prompt: "consent" }
      ).to_s
    end

    def self.exchange_code(code)
      client = build_client
      client.code = code
      client.fetch_access_token!

      credential = GoogleCredential.first_or_initialize
      attrs = {
        access_token: client.access_token,
        expires_at: Time.current + client.expires_in.to_i.seconds
      }
      attrs[:refresh_token] = client.refresh_token if client.refresh_token.present?
      credential.update!(attrs)
      credential
    end

    def self.fresh_access_token
      credential = GoogleCredential.first!
      if credential.expired?
        client = build_client
        client.refresh_token = credential.refresh_token
        client.grant_type = "refresh_token"
        client.fetch_access_token!
        credential.update!(
          access_token: client.access_token,
          expires_at: Time.current + client.expires_in.to_i.seconds
        )
      end
      credential.access_token
    end

    def self.build_client
      Signet::OAuth2::Client.new(
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        scope: SCOPES.join(" "),
        redirect_uri: "#{ENV.fetch('APP_HOST')}/admin/google_calendar/callback",
        authorization_uri: AUTHORIZATION_URI,
        token_credential_uri: TOKEN_URI
      )
    end
    private_class_method :build_client
  end
end
