require "test_helper"

class ProgramPatchServiceTest < ActiveSupport::TestCase
  def setup
    @program = programs(:user_program)
    @routine = @program.phases.first.routines.first
    @workout = @routine.workouts.first
    @we      = @workout.workout_exercises.first
  end

  test "updates existing workout exercise attributes" do
    json = {
      "program"  => { "id" => @program.id, "name" => @program.name, "duration_weeks" => @program.duration_weeks },
      "routines" => [
        {
          "id" => @routine.id, "name" => @routine.name, "description" => @routine.description,
          "workouts" => [
            {
              "id" => @workout.id, "name" => @workout.name, "description" => @workout.description,
              "exercises" => [
                {
                  "workout_exercise_id" => @we.id,
                  "workout_id"          => @workout.id,
                  "sets"                => 5,
                  "reps"                => "5",
                  "rest_seconds"        => 180,
                  "intensity_technique" => nil,
                  "load"                => "80kg"
                }
              ]
            }
          ]
        }
      ]
    }

    ProgramPatchService.new(@program, json).call

    @we.reload
    assert_equal 5,      @we.sets
    assert_equal "5",    @we.reps
    assert_equal 180,    @we.rest_seconds
    assert_equal "80kg", @we.load
  end

  test "raises ActiveRecord::RecordNotFound for unknown workout_exercise_id" do
    json = {
      "program"  => { "id" => @program.id, "name" => @program.name, "duration_weeks" => @program.duration_weeks },
      "routines" => [
        {
          "id" => @routine.id, "name" => @routine.name, "description" => nil,
          "workouts" => [
            {
              "id" => @workout.id, "name" => @workout.name, "description" => nil,
              "exercises" => [
                { "workout_exercise_id" => 999999, "workout_id" => @workout.id,
                  "sets" => 3, "reps" => "10", "rest_seconds" => 60 }
              ]
            }
          ]
        }
      ]
    }

    assert_raises(ActiveRecord::RecordNotFound) do
      ProgramPatchService.new(@program, json).call
    end
  end

  test "creates new workout exercise when workout_exercise_id is nil" do
    exercise      = exercises(:bench_press)
    initial_count = @workout.workout_exercises.count

    json = {
      "program"  => { "id" => @program.id, "name" => @program.name, "duration_weeks" => @program.duration_weeks },
      "routines" => [
        {
          "id" => @routine.id, "name" => @routine.name, "description" => nil,
          "workouts" => [
            {
              "id" => @workout.id, "name" => @workout.name, "description" => nil,
              "exercises" => [
                {
                  "workout_exercise_id" => nil,
                  "workout_id"          => @workout.id,
                  "name"                => exercise.name,
                  "muscle_group"        => exercise.muscle_group,
                  "sets"                => 3,
                  "reps"                => "12",
                  "rest_seconds"        => 90
                }
              ]
            }
          ]
        }
      ]
    }

    ProgramPatchService.new(@program, json).call

    assert_equal initial_count + 1, @workout.workout_exercises.reload.count
  end

  # call_modifications (diff-based)

  test "call_modifications: updates existing workout exercise attributes" do
    mods = [{ "workout_exercise_id" => @we.id, "sets" => 5, "reps" => "5", "rest_seconds" => 180, "load" => "80kg" }]
    ProgramPatchService.new(@program, mods).call_modifications
    @we.reload
    assert_equal 5,      @we.sets
    assert_equal "5",    @we.reps
    assert_equal 180,    @we.rest_seconds
    assert_equal "80kg", @we.load
  end

  test "call_modifications: adds new exercise when replace_workout_exercise_id is nil" do
    initial_count = @workout.workout_exercises.count
    mods = [{
      "workout_exercise_id"         => nil,
      "replace_workout_exercise_id" => nil,
      "workout_id"                  => @workout.id,
      "name"                        => "Sentadilla",
      "muscle_group"                => "Piernas",
      "sets"                        => 3,
      "reps"                        => "8-10",
      "rest_seconds"                => 90
    }]
    ProgramPatchService.new(@program, mods).call_modifications
    assert_equal initial_count + 1, @workout.workout_exercises.reload.count
  end

  test "call_modifications: replaces exercise and destroys old one" do
    initial_count = @workout.workout_exercises.count
    old_id = @we.id
    mods = [{
      "workout_exercise_id"         => nil,
      "replace_workout_exercise_id" => old_id,
      "workout_id"                  => @workout.id,
      "name"                        => "Peso Muerto",
      "muscle_group"                => "Espalda",
      "sets"                        => 4,
      "reps"                        => "6",
      "rest_seconds"                => 120
    }]
    ProgramPatchService.new(@program, mods).call_modifications
    assert_not WorkoutExercise.exists?(old_id)
    assert_equal initial_count, @workout.workout_exercises.reload.count
  end

  test "call_modifications: rejects workout_exercise_id from a different program" do
    other_program = Program.create!(name: "Otro", duration_weeks: 4, user: users(:two))
    other_phase   = other_program.phases.create!(name: "F1", order_index: 0, duration_weeks: 4)
    other_routine = Routine.create!(name: "R", user: users(:two), is_template: false)
    PhaseRoutine.create!(phase: other_phase, routine: other_routine, order_index: 0)
    other_workout = other_routine.workouts.create!(name: "W", day_number: 1, order_index: 0)
    other_we      = other_workout.workout_exercises.create!(exercise: exercises(:bench_press), sets: 3, reps: "10", order_index: 0)

    mods = [{ "workout_exercise_id" => other_we.id, "sets" => 99 }]
    assert_raises(ActiveRecord::RecordNotFound) do
      ProgramPatchService.new(@program, mods).call_modifications
    end
  end

  test "call_modifications: rejects workout_id from a different program" do
    other_program = Program.create!(name: "Otro", duration_weeks: 4, user: users(:two))
    other_phase   = other_program.phases.create!(name: "F1", order_index: 0, duration_weeks: 4)
    other_routine = Routine.create!(name: "R", user: users(:two), is_template: false)
    PhaseRoutine.create!(phase: other_phase, routine: other_routine, order_index: 0)
    other_workout = other_routine.workouts.create!(name: "W", day_number: 1, order_index: 0)

    mods = [{
      "workout_exercise_id"         => nil,
      "replace_workout_exercise_id" => nil,
      "workout_id"                  => other_workout.id,
      "name"                        => "Sentadilla",
      "muscle_group"                => "Piernas",
      "sets"                        => 3,
      "reps"                        => "8",
      "rest_seconds"                => 90
    }]
    assert_raises(ActiveRecord::RecordNotFound) do
      ProgramPatchService.new(@program, mods).call_modifications
    end
  end

  test "updates routine name and description" do
    json = {
      "program"  => { "id" => @program.id, "name" => @program.name, "duration_weeks" => @program.duration_weeks },
      "routines" => [
        {
          "id"          => @routine.id,
          "name"        => "Nuevo Nombre",
          "description" => "Nueva descripción",
          "workouts"    => []
        }
      ]
    }

    ProgramPatchService.new(@program, json).call

    @routine.reload
    assert_equal "Nuevo Nombre",      @routine.name
    assert_equal "Nueva descripción", @routine.description
  end
end
