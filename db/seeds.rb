# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding Data..."

# 1. Cleanup (Development Only)
if Rails.env.development?
  puts "Cleaning up existing data..."
  DailyMetric.destroy_all
  CoachAlert.destroy_all
  UserDietaryPlan.destroy_all
  DietaryPlan.destroy_all
  AiMessage.destroy_all
  AiConversation.destroy_all
  WorkoutExercise.destroy_all
  Workout.destroy_all
  PhaseRoutine.destroy_all
  Phase.destroy_all
  Routine.destroy_all
  Program.destroy_all
  User.destroy_all
  Exercise.destroy_all
end

# 2. Exercises Library
puts "Creating Exercises..."
squat = Exercise.find_or_create_by!(name: "Barbell Squat") do |e|
  e.muscle_group = "Legs"
  e.video_link = "https://youtube.com/shorts/squat_demo"
  e.description = "High bar back squat."
end

bench = Exercise.find_or_create_by!(name: "Barbell Bench Press") do |e|
  e.muscle_group = "Chest"
  e.video_link = "https://youtube.com/shorts/bench_demo"
end

pullup = Exercise.find_or_create_by!(name: "Pull Up") do |e|
  e.muscle_group = "Back"
  e.video_link = "https://youtube.com/shorts/pullup_demo"
end

dl = Exercise.find_or_create_by!(name: "Romanian Deadlift") do |e|
  e.muscle_group = "Posterior Chain"
  e.video_link = "https://youtube.com/shorts/rdl_demo"
end

# 3. AI Generated Routine Templates
puts "Generating 10 AI Coach Routines... (This will take 1-2 minutes due to API calls)"
ai_service = AiCoachService.new
objectives = [
  "A 3-day full body beginner strength routine.",
  "A 4-day upper/lower split for intermediate hypertrophy.",
  "A 5-day bro split for advanced bodybuilders.",
  "A 3-day push/pull/legs routine focused on basics.",
  "A 4-day athletic performance and power routine.",
  "A 5-day intense hypertrophy routine focusing on weak points (arms and calves).",
  "A 3-day minimalist time-saving routine for busy professionals.",
  "A 4-day female-focused glute and leg hypertrophy routine.",
  "A 5-day high-volume physique competition prep routine.",
  "A 3-day functional fitness and conditioning routine."
]
objectives.each_with_index do |obj, idx|
  puts "  -> Generating Routine #{idx + 1}/10: #{obj}"
max_retries = 3
retries = 0
begin
  conversation = ai_service.generate_program(
    objectives: "Create a highly realistic template routine matching the following description: #{obj}. Do not include a program object, ONLY the routines array with this single routine inside.",
    mode: "routine"
  )
  ai_service.create_records!(conversation[:conversation])
rescue => e
  puts "    [Error] #{e.message}. Retrying... (#{retries += 1}/#{max_retries})"
  sleep 5
  retry if retries < max_retries
  puts "    [Failed] Could not generate routine: #{obj}"
end

  sleep 2
end

# 4. Nutrition Templates
puts "Creating Dietary Plans..."
diet_template = DietaryPlan.create!(
  name: "Standard Cut",
  description: "High protein, moderate carb deficit.",
  calories_target: 2400,
  protein_target: 200
)

# 5. Sample Client
puts "Creating Sample Client..."
client = User.create!(
  email: "soldado@example.com",
  password: "password123",
  first_name: "Juan",
  last_name: "Soldado",
  category: :soldado,
  plan_tier: :high_ticket,
  status: :active,
  phone: "+1234567890"
)

# (No program pre-assigned so we can test Program Builder on clean slate)

# Assign Diet Instance
UserDietaryPlan.create!(
  user: client,
  calories_target: 2400,
  protein_target: 200,
  notes: "Focus on clean sources. 500g kcal deficit."
)

# 6. Bulk Data Generation

# 6.1 Exercises (50+)
puts "Generating 50+ Exercises..."
muscle_groups = [ "Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio" ]
50.times do
  Exercise.find_or_create_by!(name: "#{Faker::Verb.base.capitalize} #{Faker::Science.element}") do |e|
    e.muscle_group = muscle_groups.sample
    e.video_link = "https://youtube.com/shorts/demo_#{Faker::Alphanumeric.alpha(number: 5)}"
    e.description = Faker::Lorem.sentence
  end
end

# 6.2 Programs & Routines (Handled by AI above)

# 6.3 Dietary Plans
puts "Generating Dietary Plans..."
5.times do
  DietaryPlan.create!(
    name: "#{Faker::Food.dish} Base Plan",
    description: Faker::Lorem.sentence,
    calories_target: [ 2000, 2400, 2800, 3200 ].sample,
    protein_target: [ 150, 180, 200, 220 ].sample
  )
end

# 6.4 Users & Metrics
puts "Creating Users with Metrics..."
require 'faker'
Faker::Config.locale = 'es-AR'

70.times do
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  email = Faker::Internet.email(name: "#{first_name} #{last_name}", domain: "example.com")

  user = User.create!(
    email: email,
    password: "password123",
    first_name: first_name,
    last_name: last_name,
    phone: Faker::PhoneNumber.cell_phone,
    category: User.categories.keys.sample,
    plan_tier: User.plan_tiers.keys.sample,
    status: User.statuses.keys.sample
  )

  # Assign random active dietary plan to some users
  if rand < 0.7
    plan = DietaryPlan.all.sample
    udp = UserDietaryPlan.create!(
      user: user,
      dietary_plan: plan,
      calories_target: plan.calories_target,
      protein_target: plan.protein_target,
      active: true,
      start_date: Date.today - 30.days
    )

    # Generate 30 days of metrics
    (1..30).each do |day|
      date = Date.today - day.days
      compliant = rand < 0.8

      cals = compliant ? udp.calories_target + rand(-100..100) : udp.calories_target + rand(200..800)
      prot = compliant ? udp.protein_target + rand(-10..10) : udp.protein_target - rand(20..50)

      DailyMetric.create!(
        user: user,
        user_dietary_plan: udp,
        date_logged: date,
        calories_consumed: cals,
        protein_consumed: prot,
        steps: rand(5000..12000),
        weight: 75.0 + rand(-2.0..2.0)
      )
    end
  end
  end

# 7. Coach Alerts
puts "Creating Coach Alerts..."
users = User.all
if users.any?
  20.times do
    user = users.sample
    category = CoachAlert.categories.keys.sample

    message = case category
    when "missed_workout" then "Missed workout on #{Date.yesterday}"
    when "low_compliance" then "Compliance dropped below 50% this week"
    when "weight_spike" then "Weight increased by 2kg in 24h"
    when "check_in" then "Weekly check-in submitted"
    end

    status = CoachAlert.statuses.keys.sample

    CoachAlert.create!(
      user: user,
      category: category,
      message: message,
      status: status,
      created_at: Faker::Time.backward(days: 7)
    )
  end
end

puts "✅ Seeding Complete!"
