module Admin
  class WorkoutExercisesController < Admin::ApplicationController
    before_action :set_workout, only: %i[new create]
    before_action :set_workout_exercise, only: %i[edit update]

    def new
      @workout_exercise = @workout.workout_exercises.build
    end

    def create
      @workout_exercise = @workout.workout_exercises.build(workout_exercise_params)
      @workout_exercise.order_index = @workout.workout_exercises.count + 1

      if @workout_exercise.save
        redirect_to admin_routine_path(@workout.routine), notice: "Exercise added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # When accessed directly (not via turbo frame), redirect to the routine viewer
      unless turbo_frame_request?
        redirect_to admin_routine_path(@workout_exercise.workout.routine)
      end
    end

    def update
      if @workout_exercise.update(workout_exercise_params)
        respond_to do |format|
          # Reload inside the frame with the newly updated `workout_exercise` partial
          format.html { render partial: "admin/workout_exercises/workout_exercise", locals: { workout_exercise: @workout_exercise } }
        end
      else
        respond_to do |format|
          # Re-render the form with validation errors (unprocessable_entity is important for Turbo to catch errors)
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_workout
      @workout = Workout.find(params[:workout_id])
    end

    def set_workout_exercise
      @workout_exercise = WorkoutExercise.find(params[:id])
    end

    def workout_exercise_params
      params.require(:workout_exercise).permit(
        :exercise_id,
        :sets,
        :reps,
        :warmup_sets,
        :early_rpe,
        :last_rpe,
        :rest_seconds,
        :load,
        :intensity_technique,
        :sub_option_one,
        :sub_option_two
      )
    end
  end
end
