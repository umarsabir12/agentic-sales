require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_up(email: "new@tronsit.solutions")
    post user_registration_path, params: { user: { name: "New Person", company: "Tronsit", email: email, password: "Str0ng!pass" } }
  end

  test "sign-in and sign-up pages render" do
    get new_user_session_path
    assert_response :success
    assert_select "h2", "Sign in"
    get new_user_registration_path
    assert_response :success
    assert_select "h2", "Create your account"
  end

  test "new sign-ups wait for an admin's approval" do
    assert_difference "User.count" do
      sign_up
    end
    user = User.find_by!(email: "new@tronsit.solutions")
    assert_not user.approved?
    assert user.agent?
    assert_equal "Tronsit", user.company

    get root_path
    assert_redirected_to new_user_session_path
  end

  test "the first account on a fresh install becomes an approved admin" do
    Message.delete_all
    Ticket.delete_all
    User.delete_all
    sign_up(email: "owner@tronsit.solutions")

    owner = User.find_by!(email: "owner@tronsit.solutions")
    assert owner.admin?
    assert owner.approved?
  end

  test "admins approve pending members" do
    sign_up
    pending = User.find_by!(email: "new@tronsit.solutions")

    sign_in users(:admin)
    patch approve_admin_user_path(pending)
    assert_redirected_to admin_users_path
    assert pending.reload.approved?
  end
end
