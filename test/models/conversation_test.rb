require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "service window depends on last inbound message" do
    conversation = conversations(:ali_open)
    assert conversation.within_service_window?

    conversation.last_inbound_at = 25.hours.ago
    assert_not conversation.within_service_window?
  end

  test "take over assigns user and pauses AI" do
    conversation = conversations(:ali_open)
    conversation.take_over!(users(:agent))
    assert conversation.human_active?
    assert_equal users(:agent), conversation.assigned_user
  end

  test "inbound message updates timestamps" do
    conversation = conversations(:ali_open)
    message = conversation.messages.create!(direction: :inbound, sender_type: :customer, body: "Hello again")
    assert_equal message.created_at, conversation.reload.last_inbound_at
  end
end
