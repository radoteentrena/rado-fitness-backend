class PushNotification
  def initialize(user:, title:, body:, data: {})
    @user  = user
    @title = title
    @body  = body
    @data  = data
  end

  def deliver
    return false if @user.fcm_token.blank?

    response = self.class.fcm_client.send_v1(payload)

    if response[:status_code] == 200
      Rails.logger.info("[PushNotification] Sent to user #{@user.id}")
      true
    else
      Rails.logger.error("[PushNotification] Failed for user #{@user.id}: #{response.inspect}")
      false
    end
  rescue StandardError => e
    Rails.logger.error("[PushNotification] Error for user #{@user.id}: #{e.message}")
    false
  end

  def self.fcm_client
    @fcm_client ||= FCM.new(firebase_credentials)
  end

  def self.firebase_credentials
    Rails.application.credentials.dig(:firebase, :service_account_json) ||
      (File.read("config/firebase_credentials.json") if File.exist?("config/firebase_credentials.json")) ||
      ENV["FIREBASE_CREDENTIALS_JSON"] ||
      raise(ArgumentError, "Firebase credentials not configured. Set credentials[:firebase][:service_account_json], config/firebase_credentials.json, or FIREBASE_CREDENTIALS_JSON env var.")
  end

  private

  def payload
    {
      token: @user.fcm_token,
      notification: { title: @title, body: @body },
      data: @data.transform_keys(&:to_s).transform_values(&:to_s)
    }
  end
end
