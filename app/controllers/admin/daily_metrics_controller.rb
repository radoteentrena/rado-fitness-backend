module Admin
  class DailyMetricsController < Admin::ApplicationController
    def show
      @daily_metric = DailyMetric.find(params[:id])
      date = @daily_metric.date_logged
      @training_session = @daily_metric.user.training_sessions
        .completed
        .where(completed_at: date.beginning_of_day..date.end_of_day)
        .includes(:workout, :phase, exercise_logs: { workout_exercise: :exercise })
        .first

      render turbo_stream: turbo_stream.replace(
        "modal_frame",
        partial: "admin/shared/day_detail",
        locals: { daily_metric: @daily_metric, training_session: @training_session }
      )
    end
  end
end
