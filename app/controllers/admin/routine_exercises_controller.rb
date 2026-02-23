module Admin
  class RoutineExercisesController < Admin::ApplicationController
    before_action :set_routine_exercise, only: %i[edit update]

    def edit
      # Responds to Turbo Stream / Frame by default based on format in standard Rails
    end

    def update
      if @routine_exercise.update(routine_exercise_params)
        respond_to do |format|
          # Reload inside the frame with the newly updated `routine_exercise` partial
          format.html { render partial: "admin/routine_exercises/routine_exercise", locals: { routine_exercise: @routine_exercise } }
        end
      else
        respond_to do |format|
          # Re-render the form with validation errors (unprocessable_entity is important for Turbo to catch errors)
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_routine_exercise
      @routine_exercise = RoutineExercise.find(params[:id])
    end

    def routine_exercise_params
      params.require(:routine_exercise).permit(
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
