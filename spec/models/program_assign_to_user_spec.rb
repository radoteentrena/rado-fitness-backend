require "rails_helper"

RSpec.describe Program, "#assign_to_user" do
  let(:user) { create(:user, status: :active) }

  let(:template) do
    program = create(:program, user: nil)
    phase = create(:phase, program: program, order_index: 1, duration_weeks: 4)
    routine = create(:routine, is_template: false)
    create(:workout, routine: routine, order_index: 1)
    create(:phase_routine, phase: phase, routine: routine, order_index: 1)
    program
  end

  it "creates exactly one pending session and none skipped as superseded" do
    new_program = template.assign_to_user(user)

    sessions = TrainingSession.where(user: user, program: new_program)
    expect(sessions.count).to eq(1)
    expect(sessions.first.status).to eq("pending")
    expect(sessions.where(status: :skipped).where("skip_reason LIKE ?", "%Superseded%")).to be_empty
  end
end
