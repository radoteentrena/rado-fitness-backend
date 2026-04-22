class ProgramPatchService
  def initialize(program, updated_json)
    @program = program
    @json    = updated_json
  end

  def call_modifications
    ActiveRecord::Base.transaction do
      Array(@json).each do |mod|
        if mod["workout_exercise_id"].present?
          we = scoped_workout_exercise(mod["workout_exercise_id"])
          fields = mod.slice("sets", "reps", "rest_seconds", "intensity_technique", "load").compact
          we.update!(fields.transform_keys(&:to_sym))
        else
          WorkoutExercise.find(mod["replace_workout_exercise_id"]).destroy! if mod["replace_workout_exercise_id"].present?
          exercise = Exercise.find_or_create_by!(name: mod["name"]) do |e|
            e.muscle_group = mod["muscle_group"]
          end
          parent_workout = scoped_workout(mod["workout_id"])
          WorkoutExercise.create!(
            workout:             parent_workout,
            exercise:            exercise,
            sets:                mod["sets"],
            reps:                mod["reps"]&.to_s || "",
            rest_seconds:        mod["rest_seconds"],
            intensity_technique: mod["intensity_technique"],
            load:                mod["load"]
          )
        end
      end
    end
  end

  def call
    ActiveRecord::Base.transaction do
      Array(@json["routines"]).each do |routine_data|
        routine = Routine.find(routine_data["id"])
        routine.update!(
          name:        routine_data["name"],
          description: routine_data["description"]
        )

        Array(routine_data["workouts"]).each do |workout_data|
          workout = Workout.find(workout_data["id"])
          workout.update!(
            name:        workout_data["name"],
            description: workout_data["description"]
          )

          Array(workout_data["exercises"]).each do |ex_data|
            if ex_data["workout_exercise_id"].present?
              we = WorkoutExercise.find(ex_data["workout_exercise_id"])
              we.update!(
                sets:                ex_data["sets"],
                reps:                ex_data["reps"].to_s,
                rest_seconds:        ex_data["rest_seconds"],
                intensity_technique: ex_data["intensity_technique"],
                load:                ex_data["load"]
              )
            else
              exercise = Exercise.find_or_create_by!(name: ex_data["name"]) do |e|
                e.muscle_group = ex_data["muscle_group"]
              end
              parent_workout = Workout.find(ex_data["workout_id"])
              WorkoutExercise.create!(
                workout:             parent_workout,
                exercise:            exercise,
                sets:                ex_data["sets"],
                reps:                ex_data["reps"].to_s,
                rest_seconds:        ex_data["rest_seconds"],
                intensity_technique: ex_data["intensity_technique"],
                load:                ex_data["load"]
              )
            end
          end
        end
      end
    end
  end

  private

  def scoped_workout_exercise(id)
    WorkoutExercise
      .joins(workout: { routine: { phase_routines: :phase } })
      .where(phases: { program_id: @program.id })
      .find(id)
  end

  def scoped_workout(id)
    Workout
      .joins(routine: { phase_routines: :phase })
      .where(phases: { program_id: @program.id })
      .find(id)
  end
end
