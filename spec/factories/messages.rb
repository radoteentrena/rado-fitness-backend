FactoryBot.define do
  factory :message do
    user
    conversation
    content { "This is a test message" }
    sender_type { :client }
  end
end
