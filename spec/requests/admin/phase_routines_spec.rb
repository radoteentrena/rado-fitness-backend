require "rails_helper"

RSpec.describe "Admin::PhaseRoutines", type: :request do
  let(:user) { create(:user) }
  let(:program) { create(:program, user: user) }
  let(:phase) { create(:phase, program: program) }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /admin/phase_routines with new_routine_name_mode" do
    let(:valid_params) do
      {
        "phase_routine" => { "phase_id" => phase.id.to_s },
        "new_routine_name_mode" => "1",
        "new_routine_name" => "My New Routine",
        "program_id" => program.id.to_s
      }
    end

    context "with valid routine name" do
      it "creates a Routine and a PhaseRoutine" do
        expect {
          post admin_phase_routines_path,
               params: valid_params,
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(Routine, :count).by(1).and change(PhaseRoutine, :count).by(1)
      end

      it "creates routine with correct attributes" do
        post admin_phase_routines_path,
             params: valid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        routine = Routine.last
        expect(routine.name).to eq("My New Routine")
        expect(routine.is_template).to be(false)
        expect(routine.user).to eq(user)
      end

      it "links the routine to the correct phase" do
        post admin_phase_routines_path,
             params: valid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(PhaseRoutine.last.phase).to eq(phase)
        expect(PhaseRoutine.last.routine).to eq(Routine.last)
      end

      it "responds with turbo stream" do
        post admin_phase_routines_path,
             params: valid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "with blank routine name" do
      it "does not create a Routine or PhaseRoutine" do
        expect {
          post admin_phase_routines_path,
               params: valid_params.merge("new_routine_name" => ""),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(Routine, :count)
      end

      it "returns unprocessable entity" do
        post admin_phase_routines_path,
             params: valid_params.merge("new_routine_name" => ""),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
