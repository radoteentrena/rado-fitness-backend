require "test_helper"

class Admin::ProgramBuildersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get admin_program_builders_show_url
    assert_response :success
  end
end
