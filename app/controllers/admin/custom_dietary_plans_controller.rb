module Admin
  class CustomDietaryPlansController < Admin::ApplicationController
    def new
      @user = User.find(params[:user_id])
      @bmr = HarrisBenedict.bmr(@user)
      render layout: false
    end

    def create
      user = User.find(params[:user_id])

      UserDietaryPlan.transaction do
        user.user_dietary_plans.active.update_all(active: false)
        user.user_dietary_plans.create!(
          plan_params.merge(start_date: Date.current, active: true)
        )
      end

      redirect_to admin_user_path(user), notice: "Plan alimenticio personalizado creado."
    rescue => e
      Rails.logger.error("CustomDietaryPlan error for user #{params[:user_id]}: #{e.message}")
      redirect_to admin_user_path(params[:user_id]), alert: "Error al crear plan: #{e.message}"
    end

    private

    def plan_params
      params.require(:user_dietary_plan)
            .permit(:calories_target, :protein_target, :fats_target, :carbs_target, :notes)
    end
  end
end
