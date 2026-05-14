module Admin
  class WorkoutExercisesController < Admin::ApplicationController
    before_action :set_workout, only: %i[new create]
    before_action :set_workout_exercise, only: %i[edit update destroy swap]

    def new
      @workout_exercise = @workout.workout_exercises.build
    end

    def create
      @workout_exercise = @workout.workout_exercises.build(workout_exercise_params)
      @workout_exercise.order_index = @workout.workout_exercises.count + 1

      if @workout_exercise.save
        redirect_to admin_routine_path(@workout.routine), notice: "Exercise added."
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      unless turbo_frame_request?
        redirect_to admin_routine_path(@workout_exercise.workout.routine)
      end
    end

    def update
      if @workout_exercise.update(workout_exercise_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@workout_exercise, partial: "admin/workout_exercises/workout_exercise", locals: { workout_exercise: @workout_exercise }),
              turbo_stream.update("modal_frame", "")
            ]
          end
          format.html { render partial: "admin/workout_exercises/workout_exercise", locals: { workout_exercise: @workout_exercise } }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      routine = @workout_exercise.workout.routine
      @workout_exercise.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@workout_exercise) }
        format.html { redirect_to admin_routine_path(routine) }
      end
    end

    def swap
      @exercises = Exercise.where(muscle_group: @workout_exercise.exercise.muscle_group)
                           .where.not(id: @workout_exercise.exercise_id)
                           .order(:name)
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
        :sub_option_two,
        :time_estimate
      )
    end
  end
end
