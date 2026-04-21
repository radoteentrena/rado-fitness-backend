require "test_helper"

class Admin::ProgramAssignmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:active_user)
    ENV["ADMIN_EMAILS"] = users(:admin_user).email
    sign_in users(:admin_user)
  end

  teardown do
    ENV["ADMIN_EMAILS"] = nil
  end

  test "redirects with notice when assignment succeeds" do
    post admin_user_program_assignment_path(@user)
    assert_redirected_to admin_user_path(@user)
    assert_match "Programa asignado", flash[:notice]
  end

  test "redirects with alert when no templates available" do
    Program.where(user_id: nil).destroy_all
    post admin_user_program_assignment_path(@user)
    assert_redirected_to admin_user_path(@user)
    assert_match "No se encontraron", flash[:alert]
  end
end
