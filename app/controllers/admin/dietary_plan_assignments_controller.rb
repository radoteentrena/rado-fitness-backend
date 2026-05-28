module Admin
  class DietaryPlanAssignmentsController < Admin::ApplicationController
    def new
      @user = User.find(params[:user_id])
      @dietary_plans = DietaryPlan.order(:name)
      render layout: false
    end

    def create
      user = User.find(params[:user_id])
      dietary_plan = DietaryPlan.find(params[:dietary_plan_id])

      user.user_dietary_plans.active.update_all(active: false)

      user.user_dietary_plans.create!(
        dietary_plan:   dietary_plan,
        calories_target: dietary_plan.calories_target,
        protein_target:  dietary_plan.protein_target,
        fats_target:     dietary_plan.fats_target,
        carbs_target:    dietary_plan.carbs_target,
        notes:           dietary_plan.notes,
        start_date:      Date.current,
        active:          true
      )

      redirect_to admin_user_path(user), notice: "Plan alimenticio \"#{dietary_plan.name}\" asignado."
    rescue => e
      Rails.logger.error("DietaryPlanAssignment error for user #{params[:user_id]}: #{e.message}")
      redirect_to admin_user_path(params[:user_id]), alert: "Error al asignar plan: #{e.message}"
    end
  end
end
