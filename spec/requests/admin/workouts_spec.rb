require "rails_helper"

RSpec.describe "Admin::Workouts", type: :request do
  let(:program) { create(:program, user: create(:user)) }
  let(:phase) { create(:phase, program: program) }
  let(:routine) { create(:routine) }
  let!(:phase_routine) { create(:phase_routine, phase: phase, routine: routine) }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(program.user)
  end

  describe "GET /admin/routines/:routine_id/workouts/new" do
    it "returns turbo frame response with modal" do
      get new_admin_routine_workout_path(routine, program_id: program.id),
          headers: { "Turbo-Frame" => "modal_frame" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("modal_frame")
      expect(response.body).to include("New Workout Day")
    end
  end

  describe "POST /admin/routines/:routine_id/workouts" do
    context "with valid params and turbo_stream format" do
      it "creates a workout and responds with turbo stream" do
        expect {
          post admin_routine_workouts_path(routine),
               params: { workout: { name: "Upper Body Push", description: "Chest focus" }, program_id: program.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Workout, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "auto-assigns day_number as max + 1" do
        create(:workout, routine: routine, day_number: 3)

        post admin_routine_workouts_path(routine),
             params: { workout: { name: "New Day" }, program_id: program.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(Workout.last.day_number).to eq(4)
      end

      it "auto-assigns day_number as 1 when no prior workouts" do
        post admin_routine_workouts_path(routine),
             params: { workout: { name: "Day 1" }, program_id: program.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(Workout.last.day_number).to eq(1)
      end
    end

    context "with invalid params and turbo_stream format" do
      it "returns unprocessable entity and re-renders modal" do
        post admin_routine_workouts_path(routine),
             params: { workout: { name: "" }, program_id: program.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
