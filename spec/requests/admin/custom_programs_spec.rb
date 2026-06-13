require "rails_helper"

RSpec.describe "Admin::CustomPrograms", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /admin/users/:user_id/custom_program" do
    it "creates a blank program assigned to the user and redirects to the builder" do
      expect {
        post admin_user_custom_program_path(user)
      }.to change { user.programs.count }.by(1)

      program = user.programs.last
      expect(program.user).to eq(user)
      expect(response).to redirect_to(admin_program_builder_path(program))
    end
  end
end
