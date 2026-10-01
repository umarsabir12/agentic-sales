require "test_helper"

class AdminUsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "agents cannot manage the team" do
    sign_in users(:agent)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "admins can add team members" do
    sign_in users(:admin)
    assert_difference "User.count" do
      post admin_users_path, params: { user: { name: "New Rep", email: "rep@example.com", role: "agent", password: "secret123", password_confirmation: "secret123" } }
    end
  end
end
