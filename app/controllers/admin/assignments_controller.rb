module Admin
  class AssignmentsController < Admin::ApplicationController
    def new
      if params[:dietary_plan_id].blank?
        redirect_to admin_dietary_plans_path, alert: "Please select a dietary plan to assign."
        return
      end
      @dietary_plan = DietaryPlan.find(params[:dietary_plan_id])
      @users = User.active.order(:first_name)
    end

    def create
      dietary_plan = DietaryPlan.find(params[:dietary_plan_id])
      user = User.find(params[:user_id])

      begin
        dietary_plan.assign_to_user(user)
        redirect_to admin_user_path(user), notice: "Plan assigned successfully!"
      rescue ActiveRecord::RecordInvalid => e
        redirect_to new_admin_assignment_path(dietary_plan_id: dietary_plan.id), alert: "Failed to assign plan: #{e.record.errors.full_messages.to_sentence}"
      rescue => e
        redirect_to new_admin_assignment_path(dietary_plan_id: dietary_plan.id), alert: "An unexpected error occurred: #{e.message}"
      end
    end
  end
end
