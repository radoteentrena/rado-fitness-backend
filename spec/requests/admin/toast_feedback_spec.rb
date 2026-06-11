require "rails_helper"

RSpec.describe "Admin toast feedback", type: :request do
  let(:admin_user) { create(:user, email: "admin@example.com") }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(admin_user)
  end

  it "moves a destroy notice into flash[:toast] as success" do
    exercise = create(:exercise)
    delete admin_exercise_path(exercise)
    expect(flash[:toast]).to be_present
    expect(flash[:toast]["type"]).to eq("success")
    expect(flash[:notice]).to be_blank
  end
end
