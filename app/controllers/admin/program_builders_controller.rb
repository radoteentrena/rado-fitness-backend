class Admin::ProgramBuildersController < Admin::ApplicationController
  def show
    @program = Program.find(params[:program_id])
    # Eager load the entire tree for performance
    @phases = @program.phases.includes(routines: :user, user_dietary_plans: :dietary_plan).order(:order_index)
  end
end
