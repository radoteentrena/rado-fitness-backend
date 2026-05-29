class Api::V1::SyncController < Api::V1::BaseController
  def index
    @user = current_user
    @active_program = @user.active_program
    @dietary_plan = @user.user_dietary_plans.active.first
    @active_routine = @active_program&.current_routine
    @current_week = @active_program&.current_week
    @current_week_workouts = []
    @next_session = TrainingSession.current_for(@user)

    if @active_routine
      @current_week_workouts = @active_routine.workouts.includes(workout_exercises: :exercise).order(:day_number)
    end

    @metrics = {
      streak: @user.streak,
      days_trained: @user.days_trained,
      workout_compliance: @user.calculate_workout_compliance_score,
      metric_compliance: @user.calculate_diet_consistency_score
    }

    @user.daily_metrics.find_or_create_by(date_logged: Date.current)
  end
end
