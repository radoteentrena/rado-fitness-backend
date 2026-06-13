class ProgramRecordBuilder
  def initialize(data, user)
    @data = data
    @user = user
  end

  # Creates all DB records from AI-generated data. Returns the Program or last Routine.
  def build!
    ActiveRecord::Base.transaction do
      program, phase = build_program_and_phase

      @data["routines"]&.each_with_index do |routine_data, r_index|
        routine = build_routine(routine_data)
        PhaseRoutine.create!(phase: phase, routine: routine, order_index: r_index) if phase

        routine_data["workouts"]&.each_with_index do |workout_data, w_index|
          workout = Workout.create!(
            routine:     routine,
            name:        workout_data["name"] || "Workout #{w_index + 1}",
            description: workout_data["description"],
            day_number:  workout_data["day_number"] || (w_index + 1),
            order_index: w_index
          )

          workout_data["exercises"]&.each_with_index do |ex_data, index|
            exercise = find_or_create_exercise(ex_data)
            WorkoutExercise.create!(
              workout:             workout,
              exercise:            exercise,
              sets:                ex_data["sets"],
              reps:                ex_data["reps"].to_s,
              rest_seconds:        ex_data["rest_seconds"],
              intensity_technique: ex_data["intensity_technique"],
              warmup_sets:         ex_data["warmup_sets"],
              early_rpe:           ex_data["early_rpe"],
              last_rpe:            ex_data["last_rpe"],
              load:                ex_data["load"],
              time_estimate:       ex_data["time_estimate"],
              sub_option_one:      ex_data["sub_option_one"],
              sub_option_two:      ex_data["sub_option_two"],
              order_index:         index
            )
          end
        end
      end

      program || Routine.where(user: @user).last
    end
  end

  private

  def build_program_and_phase
    return [nil, nil] unless @data["program"]

    program = Program.create!(
      name:           @data["program"]["name"],
      description:    @data["program"]["description"],
      duration_weeks: @data["program"]["duration_weeks"],
      user:           @user
    )

    phase = Phase.create!(
      name:           "Phase 1",
      description:    "Initial phase for #{program.name}",
      duration_weeks: program.duration_weeks,
      program:        program,
      order_index:    1
    )

    [program, phase]
  end

  def build_routine(routine_data)
    Routine.create!(
      name:           routine_data["name"],
      description:    routine_data["description"],
      duration_weeks: routine_data["duration_weeks"],
      is_template:    @user.nil?,
      user:           @user
    )
  end

  def find_or_create_exercise(ex_data)
    if ex_data["existing_exercise_id"]
      Exercise.find_by(id: ex_data["existing_exercise_id"]) ||
        Exercise.find_or_create_by!(name: ex_data["name"]) { |e| e.muscle_group = ex_data["muscle_group"] }
    else
      Exercise.find_or_create_by!(name: ex_data["name"]) { |e| e.muscle_group = ex_data["muscle_group"] }
    end
  end
end
