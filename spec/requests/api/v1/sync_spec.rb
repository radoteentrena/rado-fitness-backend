require 'rails_helper'

RSpec.describe "GET /api/v1/sync", type: :request do
  let(:user) { create(:user, status: :active) }

  context "when unauthenticated" do
    it "returns 401" do
      get "/api/v1/sync"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated with no programs" do
    it "returns 200 with null active_program and empty workouts" do
      get "/api/v1/sync", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json["active_program"]).to be_nil
      expect(json["current_week_workouts"]).to eq([])
    end

    it "includes metric_compliance and workout_compliance in recent_metrics" do
      get "/api/v1/sync", headers: auth_headers(user)
      expect(json["recent_metrics"]).to include(
        "workout_compliance",
        "metric_compliance"
      )
    end

    it "does not create an empty daily metric as a side effect" do
      expect {
        get "/api/v1/sync", headers: auth_headers(user)
      }.not_to change(DailyMetric, :count)
    end
  end

  context "when authenticated with a program, phase, routine, and workouts" do
    let(:program)  { create(:program, user: user) }
    let(:phase)    { create(:phase, program: program, order_index: 1, duration_weeks: 4) }
    let(:routine)  { create(:routine, user: user) }
    let!(:phase_routine) { create(:phase_routine, phase: phase, routine: routine, order_index: 1) }
    let!(:workout) { create(:workout, routine: routine, day_number: 1, order_index: 1) }

    it "returns 200 with active_program present" do
      get "/api/v1/sync", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json["active_program"]).to include("id" => program.id, "name" => program.name)
    end

    it "returns current_week_workouts with the routine's workouts" do
      get "/api/v1/sync", headers: auth_headers(user)
      expect(json["current_week_workouts"]).to be_an(Array)
      expect(json["current_week_workouts"].length).to eq(1)
      expect(json["current_week_workouts"].first["id"]).to eq(workout.id)
    end
  end
end
