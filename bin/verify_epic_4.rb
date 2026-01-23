#!/usr/bin/env ruby
require_relative "../config/environment"

puts "== Verifying Epic 4: Deep Training Hierarchy =="

# 1. Setup
puts "\n[1] Setting up test data..."
user = User.create!(first_name: "Test", last_name: "Civil", email: "test_epic4_#{Time.now.to_i}@example.com", category: :civil)
program_template = Program.create!(name: "Hypertrophy 1.0 (Template)", duration_weeks: 12, description: "Base template")

routine_template = Routine.create!(
  name: "Mesocycle 1 (Template)",
  program: program_template,
  is_template: true,
  duration_weeks: 4
)

exercise = Exercise.first || Exercise.create!(name: "Squat", muscle_group: "Legs")

RoutineExercise.create!(
  routine: routine_template,
  exercise: exercise,
  sets: 3,
  reps: "8-12",
  day_number: 1,
  day_name: "Leg Day"
)

puts "    - Created User: #{user.email}"
puts "    - Created Program Template: #{program_template.name}"
puts "    - Created Routine Template: #{routine_template.name}"

# 2. Execution
puts "\n[2] Executing Program#assign_to_user..."
assigned_program = program_template.assign_to_user(user)

# 3. Assertions
puts "\n[3] Asserting results..."

# Verify Program
if assigned_program.persisted? && assigned_program.user == user && assigned_program.name == "Hypertrophy 1.0 (Template)"
  puts "✅ Program assigned correctly."
else
  puts "❌ Program assignment failed."
end

# Verify Routines
assigned_routine = assigned_program.routines.first
if assigned_routine && assigned_routine.user == user && assigned_routine.name.include?("(Copy)")
  puts "✅ Routine cloned and assigned correctly."
else
  puts "❌ Routine cloning failed."
end

# Verify Routine Exercises
if assigned_routine.routine_exercises.count == 1 && assigned_routine.routine_exercises.first.exercise == exercise
  puts "✅ Routine Exercises cloned correctly."
else
  puts "❌ Routine Exercise cloning failed."
end

# Verify Template Integrity
if program_template.user.nil? && routine_template.is_template
  puts "✅ Templates remain untouched."
else
  puts "❌ Templates were modified (BAD)."
end

puts "\n== Verification Complete =="
