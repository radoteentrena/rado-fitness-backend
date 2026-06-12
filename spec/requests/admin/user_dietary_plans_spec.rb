require "rails_helper"

RSpec.describe "Admin::UserDietaryPlans", type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:user_dietary_plan, user: user) }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /admin/users/:id" do
    it "renders the dietary card with the inline edit form" do
      plan
      get admin_user_path(user)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("macro-calculator")
      expect(response.body).to include("playlist_add")
    end
  end

  describe "PATCH /admin/user_dietary_plans/:id with return_to_user" do
    it "updates targets and redirects to the user page" do
      patch admin_user_dietary_plan_path(plan), params: {
        return_to_user: "1",
        user_dietary_plan: { calories_target: 2800, protein_target: 210, fats_target: 93, carbs_target: 280 }
      }

      expect(plan.reload.calories_target).to eq(2800)
      expect(response).to redirect_to(admin_user_path(user))
    end
  end
end
