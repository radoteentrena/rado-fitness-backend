module Admin
  class DailyMetricsController < Admin::ApplicationController
    def show
      @daily_metric = DailyMetric.find(params[:id])
      render turbo_stream: turbo_stream.replace("modal_frame", partial: "admin/daily_metrics/show", locals: { daily_metric: @daily_metric })
    end
  end
end
