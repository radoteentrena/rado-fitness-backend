class GoogleCredential < ApplicationRecord
  encrypts :access_token
  encrypts :refresh_token

  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at < Time.current
  end
end
