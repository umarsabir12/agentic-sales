require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:agent) }

  test "board and ticket pages render" do
    get tickets_path
    assert_response :success
    get ticket_path(tickets(:ali_inverter))
    assert_response :success
    get new_ticket_path(conversation_id: conversations(:ali_open).id)
    assert_response :success
  end

  test "creates a manual ticket" do
    assert_difference "Ticket.count" do
      post tickets_path, params: { ticket: { title: "Follow up", contact_id: contacts(:ali).id, priority: "low" } }
    end
    assert Ticket.last.source_manual?
  end
end
