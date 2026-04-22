FactoryBot.define do
  factory :conversation do
    user
    last_message_at { 1.hour.ago }
    read_by_coach_at { nil }
  end
end
