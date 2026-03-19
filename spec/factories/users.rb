FactoryBot.define do
  factory :user do
    first_name { "Test" }
    last_name  { "User" }
    sequence(:email) { |n| "test#{n}@example.com" }
    phone      { "+5491155551234" }
    status     { :lead }
    plan_tier  { :basic }
    category   { :pelele }
  end
end
