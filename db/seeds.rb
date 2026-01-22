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
  description: "High protein, moderate carb deficit."
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
# In a real app, we'd clone the template. For seed simplicity, we verify association.
# Here we represent the "assigned" program. In future, we clone Protocol.
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

puts "✅ Seeding Complete!"
