FactoryBot.define do
  factory :daily_metric do
    association :user
    date_logged { Date.current }
    weight { 80.0 }
  end
end
