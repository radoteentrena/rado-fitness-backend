class Api::V1::DailyMetricsController < Api::V1::BaseController
  def index
    reference_date = if params[:month].present?
      Date.strptime(params[:month], "%Y-%m") rescue Date.current
    else
      Date.current
    end

    @month   = reference_date.strftime("%Y-%m")
    @metrics = current_user.daily_metrics
      .where(date_logged: reference_date.beginning_of_month..reference_date.end_of_month)
      .order(date_logged: :asc)
  end

  def create
    @metric = current_user.daily_metrics.find_or_initialize_by(date_logged: metric_params[:date_logged] || Date.today)

    if @metric.update(metric_params)
      render "api/v1/daily_metrics/show", status: :ok
    else
      render json: { errors: @metric.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def metric_params
    params.require(:daily_metric).permit(:date_logged, :weight, :calories_consumed, :protein_consumed, :fats, :carbs, :workout_completed)
  end
end
