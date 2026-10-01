require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders the dashboard" do
    sign_in users(:agent)
    get root_path
    assert_response :success
    assert_select "h1", "Dashboard"
  end
end
