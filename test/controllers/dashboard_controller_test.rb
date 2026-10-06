require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:agent) }

  test "renders the dashboard with a greeting and the attention banner" do
    conversations(:ali_open).update!(status: :human_active)

    get root_path
    assert_response :success
    assert_select "h1", /Good (morning|afternoon|evening), Sales/
    assert_select "[role=status]", /1 conversation\s+is waiting for a human reply/
    assert_select "html[data-theme=light]"
  end

  test "uses the theme saved in the cookie" do
    cookies[:theme] = "dark"
    get root_path
    assert_select "html[data-theme=dark]"
  end

  test "chart range can be switched" do
    get root_path(range: 30)
    assert_response :success
    assert_select "figure table tbody tr", 30
  end

  test "unassigned tickets can be assigned inline" do
    ticket = tickets(:ali_inverter)
    patch ticket_path(ticket), params: { back: 1, ticket: { assignee_id: users(:agent).id } }, headers: { "HTTP_REFERER" => root_url }
    assert_redirected_to root_url
    assert_equal users(:agent), ticket.reload.assignee
  end

  test "live inbox actions return to the dashboard" do
    patch take_over_conversation_path(conversations(:ali_open)), headers: { "HTTP_REFERER" => root_url }
    assert_redirected_to root_url
  end
end
