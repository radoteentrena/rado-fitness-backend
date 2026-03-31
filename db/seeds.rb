# Production Exercises Seed
# Exercises from fitness programming books for Rado Fitness

exercises = [
  "Dumbbell Incline Press",
  "Seated Row",
  "Single-Leg Hip Thrust",
  "Banded Side-Lying Clam",
  "Knee-Banded Hip Thrust",
  "Dumbbell Overhead Press",
  "Dumbbell Reverse Lunge",
  "Lat Pulldown",
  "Dumbbell Back Extension",
  "Lateral Raise",
  "Sumo Deadlift",
  "Close-Grip Bench Press",
  "Pause Back Squat",
  "Negative Chin-up",
  "Pause Barbell Hip Thrust",
  "Banded Standing Hip Abduction",
  "Overhead Triceps Extension",
  "Bicep Curl",
  "Standing Calf Raise",
  "Dumbbell Lateral Raise",
  "Hammer Curl",
  "Seated Leg Curl",
  "Seated Calf Raise",
  "Decline Dumbbell Press",
  "Cable Flyes",
  "Dumbbell Row",
  "Back Extension",
  "Leg Press",
  "Rear Delt Flyes",
  "Dumbbell Front Raise",
  "Cable Face Pulls",
  "Concentration Curl",
  "Triceps Pushdown",
  "Box Jump",
  "Barbell Hip Thrust",
  "Dumbbell Front Squat",
  "Cable Kickback",
  "Glute Ham Raise",
  "Military Press",
  "Barbell Squat",
  "Barbell Bench Press",
  "Pull Up",
  "Romanian Deadlift"
]

exercises.each do |exercise_name|
  Exercise.find_or_create_by!(name: exercise_name)
  puts "✓ Created: #{exercise_name}"
end

puts "\n✅ Seeded #{exercises.count} exercises"
