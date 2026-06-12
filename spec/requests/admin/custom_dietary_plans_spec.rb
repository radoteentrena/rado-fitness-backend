require "rails_helper"

RSpec.describe "Admin::CustomDietaryPlans", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /admin/users/:user_id/custom_dietary_plan" do
    let(:params) do
      { user_dietary_plan: { calories_target: 2500, protein_target: 188,
                             fats_target: 83, carbs_target: 250, notes: "Corte" } }
    end

    it "creates an active custom plan and deactivates previous ones" do
      old_plan = create(:user_dietary_plan, user: user, active: true)

      post admin_user_custom_dietary_plan_path(user), params: params

      expect(old_plan.reload.active).to be(false)
      new_plan = user.user_dietary_plans.active.last
      expect(new_plan.dietary_plan).to be_nil
      expect(new_plan.calories_target).to eq(2500)
      expect(new_plan.start_date).to eq(Date.current)
      expect(response).to redirect_to(admin_user_path(user))
    end
  end

  describe "GET /admin/users/:user_id/custom_dietary_plan/new" do
    it "renders the modal" do
      get new_admin_user_custom_dietary_plan_path(user)
      expect(response).to have_http_status(:ok)
    end
  end
end
