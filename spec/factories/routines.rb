FactoryBot.define do
  factory :routine do
    sequence(:name) { |n| "Routine #{n}" }
    is_template { false }
  end
end
