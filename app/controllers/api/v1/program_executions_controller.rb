class Api::V1::ProgramExecutionsController < Api::V1::BaseController
  def create
    @execution = current_user.program_executions.build(execution_params)

    if @execution.save
      # Optionally, we could also log a DailyMetric here automatically indicating "workout_completed: true"
      render json: { id: @execution.id, message: "Workout successfully logged" }, status: :created
    else
      render json: { errors: @execution.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def execution_params
    p = params.require(:program_execution).permit(
      :workout_id, :routine_id,
      :completed_at,
      :duration_minutes,
      exercise_logs_attributes: [
        :workout_exercise_id, :routine_exercise_id,
        actual_sets: [ :reps, :load, :rir ]
      ]
    )
    p[:workout_id] ||= p.delete(:routine_id)
    p[:exercise_logs_attributes]&.each do |log|
      log[:workout_exercise_id] ||= log.delete(:routine_exercise_id)
    end
    p
  end
end
