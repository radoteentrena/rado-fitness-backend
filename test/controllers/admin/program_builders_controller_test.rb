require "test_helper"

class Admin::ProgramBuildersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @program = programs(:one)
    ENV["ADMIN_EMAILS"] = users(:one).email
    sign_in users(:one)
  end

  teardown do
    ENV["ADMIN_EMAILS"] = nil
  end

  test "should get show" do
    get admin_program_builder_url(@program)
    assert_response :success
  end
end
