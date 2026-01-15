# db/seeds.rb

# Mock mailer for seeds
class User
  def send_welcome_email
    # No-op during seeding
  end
end

puts "🌱 Seeding Database..."

# 1. Cleanup
puts "🧹 Cleaning up old data..."
RoutineItem.destroy_all
Routine.destroy_all
DailyMetric.destroy_all
User.destroy_all
Exercise.destroy_all

# 2. Create Exercises
puts "🏋️‍♀️ Creating Exercises..."

exercises_data = [
  # Legs (Quads)
  { name: "Barbell Squat", video_link: "https://www.youtube.com/watch?v=ultWZbGWL54", muscle_group: "Quads" },
  { name: "Leg Press", video_link: "https://www.youtube.com/watch?v=IZxyjW7MPJQ", muscle_group: "Quads" },
  { name: "Bulgarian Split Squat", video_link: "https://www.youtube.com/watch?v=2C-uNgKwPLE", muscle_group: "Quads" },
  { name: "Leg Extension", video_link: "https://www.youtube.com/watch?v=YyvSfVjQeL0", muscle_group: "Quads" },
  { name: "Goblet Squat", video_link: "https://www.youtube.com/watch?v=MeIiIdhvXT4", muscle_group: "Quads" },

  # Legs (Hamstrings/Glutes)
  { name: "Romanian Deadlift", video_link: "https://www.youtube.com/watch?v=JCXUYuzwNrM", muscle_group: "Hamstrings" },
  { name: "Lying Leg Curl", video_link: "https://www.youtube.com/watch?v=1Tq3QdYUuHs", muscle_group: "Hamstrings" },
  { name: "Seated Leg Curl", video_link: "https://www.youtube.com/watch?v=F488k67BTNo", muscle_group: "Hamstrings" },
  { name: "Hip Thrust", video_link: "https://www.youtube.com/watch?v=SEDQd4hLO6k", muscle_group: "Glutes" },
  { name: "Glute Kickback Cable", video_link: "https://www.youtube.com/watch?v=nlc2l4Dbd8g", muscle_group: "Glutes" },

  # Chest
  { name: "Barbell Bench Press", video_link: "https://www.youtube.com/watch?v=rT7DgCr-3pg", muscle_group: "Chest" },
  { name: "Incline Dumbbell Press", video_link: "https://www.youtube.com/watch?v=8iPEnn-ltC8", muscle_group: "Chest" },
  { name: "Cable Fly", video_link: "https://www.youtube.com/watch?v=Iwe6AmxVf7o", muscle_group: "Chest" },
  { name: "Push Up", video_link: "https://www.youtube.com/watch?v=IODxDxX7oi4", muscle_group: "Chest" },
  { name: "Dips", video_link: "https://www.youtube.com/watch?v=2z8JmcrW-As", muscle_group: "Chest" },

  # Back
  { name: "Pull Up", video_link: "https://www.youtube.com/watch?v=eGo4IYlbE5g", muscle_group: "Back" },
  { name: "Lat Pulldown", video_link: "https://www.youtube.com/watch?v=CAwf7n6Luuc", muscle_group: "Back" },
  { name: "Barbell Row", video_link: "https://www.youtube.com/watch?v=9efgcGunQWu", muscle_group: "Back" },
  { name: "Seated Cable Row", video_link: "https://www.youtube.com/watch?v=GZbfZ033f74", muscle_group: "Back" },
  { name: "Face Pull", video_link: "https://www.youtube.com/watch?v=rep-qVOkqgk", muscle_group: "Shoulders" },

  # Shoulders
  { name: "Overhead Press", video_link: "https://www.youtube.com/watch?v=QAQ64hK4Xxs", muscle_group: "Shoulders" },
  { name: "Dumbbell Lateral Raise", video_link: "https://www.youtube.com/watch?v=3VcKaXpzqRo", muscle_group: "Shoulders" },
  { name: "Cable Lateral Raise", video_link: "https://www.youtube.com/watch?v=PzmH934rhKc", muscle_group: "Shoulders" },
  { name: "Rear Delt Fly", video_link: "https://www.youtube.com/watch?v=0G38FlW58C8", muscle_group: "Shoulders" },

  # Arms
  { name: "Barbell Bicep Curl", video_link: "https://www.youtube.com/watch?v=kwG2ipFRgfo", muscle_group: "Biceps" },
  { name: "Hammer Curl", video_link: "https://www.youtube.com/watch?v=zC3nLlEvin4", muscle_group: "Biceps" },
  { name: "Tricep Rope Pushdown", video_link: "https://www.youtube.com/watch?v=vB5OHsJ3EME", muscle_group: "Triceps" },
  { name: "Skull Crusher", video_link: "https://www.youtube.com/watch?v=d_KZxkY_0cM", muscle_group: "Triceps" },

  # Core
  { name: "Plank", video_link: "https://www.youtube.com/watch?v=ASdvN_XEl_c", muscle_group: "Core" },
  { name: "Hanging Leg Raise", video_link: "https://www.youtube.com/watch?v=Pr1ieGZ5atk", muscle_group: "Core" },
  { name: "Cable Crunch", video_link: "https://www.youtube.com/watch?v=6GMkpQ0uWKc", muscle_group: "Core" },

  # Cardio
  { name: "Treadmill Run", video_link: "", muscle_group: "Cardio" },
  { name: "Elliptical", video_link: "", muscle_group: "Cardio" },
  { name: "Stairmaster", video_link: "", muscle_group: "Cardio" }
]

created_exercises = []
exercises_data.each do |ex_data|
  created_exercises << Exercise.create!(ex_data)
end
puts "   -> Created #{created_exercises.count} exercises."

# 3. Create Users
puts "👥 Creating Users..."

# Create Admin User
admin = User.create!(
  first_name: "Rado",
  last_name: "Coach",
  email: "admin@rado.com",
  password: "password",
  status: :active,
  plan_tier: :high_ticket
)
puts "   -> Created Admin: #{admin.email}"

# Create 50 Users
50.times do
  User.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.unique.email,
    password: "password",
    status: User.statuses.keys.sample,
    plan_tier: User.plan_tiers.keys.sample
  )
end
puts "   -> Created 50 random users."


# 4. Create Routine Templates
puts "📋 Creating Routine Templates..."

templates = [
  { name: "Push Day A (Hypertrophy)", description: "Chest, Shoulders, Triceps focus" },
  { name: "Pull Day A (Hypertrophy)", description: "Back, Rear Delts, Biceps focus" },
  { name: "Leg Day A (Quad Focus)", description: "Quads and Calves" },
  { name: "Leg Day B (Glute/Ham Focus)", description: "Posterior Chain focus" },
  { name: "Upper Body Power", description: "Heavy compound movements for upper body" },
  { name: "Lower Body Power", description: "Heavy compound movements for lower body" },
  { name: "Full Body Beginner A", description: "Basic compound layout" },
  { name: "Full Body Beginner B", description: "Alternative compounds" },
  { name: "Glute Specialist 1", description: "High frequency glute training" },
  { name: "Shoulder Specialist 1", description: "Delt capping focus" }
]

templates.each do |t|
  routine = Routine.create!(
    name: t[:name],
    description: t[:description],
    user: admin # Assigned to admin acts as a 'Template'
  )

  # Add 5-7 random exercises to each routine
  exercises_sample = created_exercises.sample(rand(5..7))

  exercises_sample.each_with_index do |ex, index|
    RoutineItem.create!(
      routine: routine,
      exercise: ex,
      order_index: index + 1,
      sets: rand(3..4),
      reps: [ "8-12", "10-15", "6-8", "12-20" ].sample,
      rir: rand(1..3),
      rest_seconds: [ 60, 90, 120, 180 ].sample
    )
  end
end
puts "   -> Created #{templates.count} routine templates with items."

puts "✅ Seeding Complete!"
