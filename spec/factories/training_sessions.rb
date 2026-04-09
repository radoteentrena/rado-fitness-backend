FactoryBot.define do
  factory :training_session do
    association :user
    association :program
    association :phase
    association :routine
    association :workout
    cycle_number { 1 }
    session_number { 1 }
    status { :pending }
  end
end
