require "rails_helper"

RSpec.describe "Admin toast feedback", type: :request do
  let(:admin_user) { create(:user, email: "admin@example.com") }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(admin_user)
  end

  it "renders the admin routines index with delete links using confirm_delete_data" do
    create(:routine)
    get admin_routines_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("confirm-trigger")
  end

  it "routes the programs index delete through the confirm modal, not native confirm" do
    create(:program, user: nil)
    get admin_programs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("confirm-trigger")
    expect(response.body).not_to include("no se puede deshacer")
  end

  it "routes the exercises index delete through the confirm modal, not native confirm" do
    create(:exercise)
    get admin_exercises_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("confirm-trigger")
    expect(response.body).not_to include("no se puede deshacer")
  end

  it "moves a destroy notice into flash[:toast] as success" do
    exercise = create(:exercise)
    delete admin_exercise_path(exercise)
    expect(flash[:toast]).to be_present
    expect(flash[:toast]["type"]).to eq("success")
    expect(flash[:notice]).to be_blank
  end

  it "blocks deleting an assigned program with an error toast" do
    program = create(:program, user: create(:user))
    delete admin_program_path(program)
    expect(Program.exists?(program.id)).to be(true)
    expect(flash[:toast]["type"]).to eq("error")
  end

  it "deletes an unassigned program template with a success toast" do
    program = create(:program, user: nil)
    delete admin_program_path(program)
    expect(Program.exists?(program.id)).to be(false)
    expect(flash[:toast]["type"]).to eq("success")
  end

  it "blocks deleting an assigned routine with an error toast" do
    routine = create(:routine, user: create(:user))
    delete admin_routine_path(routine)
    expect(Routine.exists?(routine.id)).to be(true)
    expect(flash[:toast]["type"]).to eq("error")
  end
end
