#!/usr/bin/env ruby
require_relative "../config/environment"

puts "== Verifying Epic 4.1: Dietary Architecture  =="

# 1. Setup
puts "\n[1] Setting up test data..."
user = User.create!(first_name: "Diet", last_name: "Tester", email: "diet_#{Time.now.to_i}@test.com")

template = DietaryPlan.create!(
  name: "Cutting Phase 1",
  calories_target: 2000,
  protein_target: 180,
  notes: "Stick to the plan."
)

puts "    - User: #{user.email}"
puts "    - Template: #{template.name}"

# 2. Assign Plan
puts "\n[2] Assigning Plan to User..."
template.assign_to_user(user)

user_plan = user.user_dietary_plans.active.last
if user_plan && user_plan.calories_target == 2000
    puts "✅ User Plan created with correct targets."
else
    puts "❌ Plan assignment failed."
end

# 3. Create Metric (Auto-link)
puts "\n[3] Logging Daily Metric..."
metric1 = DailyMetric.create!(
    user: user,
    date_logged: Date.today,
    weight: 80.0,
    calories_consumed: 1950,
    raw_message_content: "Log 1"
)

if metric1.user_dietary_plan == user_plan
    puts "✅ Metric 1 linked to Active Plan."
else
    puts "❌ Metric 1 linking failed."
end

# 4. Create Second Metric & Verify Stats
puts "\n[4] Logging Second Metric..."
metric2 = DailyMetric.create!(
    user: user,
    date_logged: Date.tomorrow,
    weight: 79.5,
    calories_consumed: 2050,
    raw_message_content: "Log 2"
)

# 1950 + 2050 = 4000 / 2 = 2000
# 80.0 -> 79.5 = -0.5

puts "    - Avg Cals: #{user_plan.average_calories}"
puts "    - Avg Weight: #{user_plan.average_weight}"
puts "    - Progress: #{user_plan.weight_progress}"

if user_plan.average_calories == 2000 && user_plan.weight_progress == -0.5
    puts "✅ Averages & Progress calculated correctly."
else
    puts "❌ Calculation failed."
end

puts "\n== Verification Complete =="
