class Api::V1::SyncController < Api::V1::BaseController
  def index
    @user = current_user
    @active_program = @user.programs.last
    @active_routine = @active_program&.routines&.first
    @current_week_workouts = []

    if @active_routine
      # In a real scenario we'd query by current week, but since we are MVP
      # let's return all workouts for this specific Block/Routine
      @current_week_workouts = @active_routine.workouts.includes(workout_exercises: :exercise).order(:day_number)
    end

    @metrics = {
      workout_compliance: @user.calculate_workout_compliance_score,
      metric_compliance: @user.calculate_diet_consistency_score
    }
  end
end
