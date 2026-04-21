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
