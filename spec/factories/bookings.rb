FactoryBot.define do
  factory :booking do
    association :user
    scheduled_at { 2.days.from_now.change(hour: 10, min: 0, sec: 0) }
    google_event_id { "google_event_abc123" }
    meet_link { "https://meet.google.com/abc-defg-hij" }
    status { :confirmed }
  end
end
