FactoryBot.define do
  factory :google_credential do
    access_token { "ya29.test_access_token" }
    refresh_token { "1//test_refresh_token" }
    expires_at { 1.hour.from_now }
  end
end
