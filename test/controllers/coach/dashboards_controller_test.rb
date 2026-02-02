require "test_helper"

class Coach::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get coach_dashboards_show_url
    assert_response :success
  end
end
