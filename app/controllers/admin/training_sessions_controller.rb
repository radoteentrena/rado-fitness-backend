module Admin
  class TrainingSessionsController < Admin::ApplicationController
    def show
      @training_session = TrainingSession.includes(
        :phase, :workout,
        exercise_logs: { workout_exercise: :exercise }
      ).find(params[:id])

      date = @training_session.completed_at&.to_date
      @daily_metric = date && DailyMetric.find_by(
        user: @training_session.user,
        date_logged: date
      )

      render turbo_stream: turbo_stream.replace(
        "modal_frame",
        partial: "admin/shared/day_detail",
        locals: { daily_metric: @daily_metric, training_session: @training_session }
      )
    end
  end
end
