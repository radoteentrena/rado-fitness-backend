module Admin
  class CoachSchedulesController < Admin::ApplicationController
    def index
      @page      = Administrate::Page::Collection.new(dashboard)
      @resources = CoachSchedule.order(:day_of_week).page(params[:_page])
      render locals: { resources: @resources, page: @page, search_term: nil, show_search_bar: false }
    end

    def edit
      @resource = CoachSchedule.find(params[:id])
      render locals: { page: Administrate::Page::Form.new(dashboard, @resource) }
    end

    def update
      @resource = CoachSchedule.find(params[:id])
      if @resource.update(resource_params)
        redirect_to admin_coach_schedules_path, notice: "Horario actualizado."
      else
        render :edit, locals: { page: Administrate::Page::Form.new(dashboard, @resource) }, status: :unprocessable_entity
      end
    end

    private

    def dashboard
      CoachScheduleDashboard.new
    end

    def resource_params
      params.require(:coach_schedule).permit(:start_hour, :end_hour, :active)
    end
  end
end
