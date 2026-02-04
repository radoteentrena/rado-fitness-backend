module Admin
  class AssignmentsController < Admin::ApplicationController
    def new
      @dietary_plan = DietaryPlan.find(params[:dietary_plan_id])
      @users = User.active.order(:first_name)
    end

    def create
      dietary_plan = DietaryPlan.find(params[:dietary_plan_id])
      user = User.find(params[:user_id])

      begin
        dietary_plan.assign_to_user(user)
        redirect_to admin_user_path(user), notice: "Plan assigned successfully!"
      rescue => e
        redirect_to new_admin_assignment_path(dietary_plan_id: dietary_plan.id), alert: "Failed: #{e.message}"
      end
    end
  end
end
