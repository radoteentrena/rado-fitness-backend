# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding Data..."

# 1. Cleanup (Development Only)
if Rails.env.development?
  puts "Cleaning up existing data..."
  RoutineExercise.destroy_all
  Routine.destroy_all
  Program.destroy_all
  UserDietaryPlan.destroy_all
  DietaryPlan.destroy_all
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

# 3. Training Templates (Program -> Routine -> Exercises)
puts "Creating Programs..."
program = Program.create!(
  name: "Hypertrophy Masterclass",
  description: "12-week program focused on accumulation and intensification.",
  duration_weeks: 12
)

# Block 1: Accumulation (Weeks 1-4)
block_1 = Routine.create!(
  name: "Phase 1: Accumulation",
  description: "High volume, moderate intensity. Focus on technique and capacity.",
  duration_weeks: 4,
  program: program,
  is_template: true
)

# Day 1: Lower Body (Monday)
RoutineExercise.create!([
  {
    routine: block_1,
    exercise: squat,
    day_number: 1,
    day_name: "Lower Body A",
    sets: 3,
    reps: "8-12",
    load: "RPE 7",
    rir: "2",
    rest_seconds: 180,
    warmup: true,
    instructions: "Focus on depth and control."
  },
  {
    routine: block_1,
    exercise: dl,
    day_number: 1,
    day_name: "Lower Body A",
    sets: 3,
    reps: "10-15",
    load: "RPE 8",
    rir: "1",
    rest_seconds: 120,
    warmup: false
  }
])

# Day 2: Upper Body (Tuesday)
RoutineExercise.create!([
  {
    routine: block_1,
    exercise: bench,
    day_number: 2,
    day_name: "Upper Body A",
    sets: 4,
    reps: "8-12",
    load: "RPE 8",
    rir: "1",
    rest_seconds: 120,
    warmup: true
  },
  {
    routine: block_1,
    exercise: pullup,
    day_number: 2,
    day_name: "Upper Body A",
    sets: 4,
    reps: "AMRAP",
    load: "Bodyweight",
    rir: "0",
    rest_seconds: 120,
    warmup: false
  }
])

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

# Assign Program Instance
puts "Assigning Program to Client..."
user_program = Program.create!(
  name: "Juan's Hypertrophy",
  description: "Customized instantiation.",
  duration_weeks: 12,
  user: client
)

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
muscle_groups = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio"]
50.times do
  Exercise.find_or_create_by!(name: "#{Faker::Verb.base.capitalize} #{Faker::Science.element}") do |e|
    e.muscle_group = muscle_groups.sample
    e.video_link = "https://youtube.com/shorts/demo_#{Faker::Alphanumeric.alpha(number: 5)}"
    e.description = Faker::Lorem.sentence
  end
end

# 6.2 Programs & Routines
puts "Generating Programs & Routines..."
10.times do
  prog = Program.create!(
    name: "#{Faker::Marketing.buzzwords.split.map(&:capitalize).join(' ')} Protocol",
    description: Faker::Lorem.paragraph,
    duration_weeks: [8, 12, 16].sample
  )

  # Create 2-3 Routines per Program
  rand(2..3).times do |i|
    routine = Routine.create!(
      name: "Phase #{i + 1}: #{Faker::Science.element} Block",
      description: Faker::Lorem.sentence,
      duration_weeks: 4,
      program: prog,
      is_template: true
    )

    # Add random exercises to routine
    Exercise.all.sample(rand(4..8)).each_with_index do |ex, idx|
      RoutineExercise.create!(
        routine: routine,
        exercise: ex,
        day_number: rand(1..4),
        day_name: "Day #{rand(1..4)}",
        sets: rand(3..5),
        reps: ["8-12", "5x5", "AMRAP", "15-20"].sample,
        load: "RPE #{rand(6..9)}",
        rest_seconds: [60, 90, 120, 180].sample,
        instructions: Faker::Lorem.sentence
      )
    end
  end
end

# 6.3 Dietary Plans
puts "Generating Dietary Plans..."
5.times do
  DietaryPlan.create!(
    name: "#{Faker::Food.dish} Base Plan",
    description: Faker::Lorem.sentence,
    calories_target: [2000, 2400, 2800, 3200].sample,
    protein_target: [150, 180, 200, 220].sample
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

puts "✅ Seeding Complete!"
