# Verify Exercise
puts "--- Creating Exercise ---"
exercise = Exercise.create!(name: "Squat Test", muscle_group: "Legs", description: "Test squat")
puts "Exercise created: #{exercise.name}"

# Verify Routine (Template)
puts "--- Creating Routine Template ---"
template = Routine.create!(name: "Leg Day Template", is_template: true, user: nil)
puts "Routine Template created: #{template.name} (Template: #{template.is_template})"

# Verify RoutineItem
puts "--- Adding Routine Item ---"
item = RoutineItem.create!(routine: template, exercise: exercise, sets: 4, reps: "8-12", rest_seconds: 90)
puts "RoutineItem added: #{item.exercise.name} to #{item.routine.name}"

# Verify Associations
puts "--- Verifying Associations ---"
puts "Routine has #{template.exercises.count} exercises"
raise "Association failed" unless template.exercises.first == exercise

# Verify Cloning
puts "--- Verifying Cloning ---"
user = User.create!(email: "test_cloning_#{Time.now.to_i}@example.com", password: "password", first_name: "Clone", last_name: "Tester")
cloned_routine = template.clone_to_user(user)

puts "Cloned Routine: #{cloned_routine.name}"
puts "Cloned Routine User: #{cloned_routine.user.email}"
puts "Cloned Routine Items: #{cloned_routine.routine_items.count}"
puts "Cloned Routine Template Status: #{cloned_routine.is_template}"

raise "Clone failed: User mismatch" unless cloned_routine.user == user
raise "Clone failed: Item count mismatch" unless cloned_routine.routine_items.count == template.routine_items.count
raise "Clone failed: Is template" if cloned_routine.is_template

puts "Verification Successful!"
