require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:agent) }

  test "redirects to sign in when signed out" do
    sign_out :user
    get conversations_path
    assert_redirected_to new_user_session_path
  end

  test "lists and shows conversations" do
    get conversations_path
    assert_response :success
    get conversation_path(conversations(:ali_open))
    assert_response :success
  end

  test "staff reply pauses the AI" do
    conversation = conversations(:ali_open)
    post conversation_messages_path(conversation), params: { message: { body: "Hi Ali, Sara here." } }
    assert_redirected_to conversation
    assert conversation.reload.human_active?
    assert conversation.messages.last.sent_by_staff?
  end

  test "starts a new conversation with a template" do
    get new_conversation_path
    assert_response :success

    assert_difference "Conversation.count" do
      post conversations_path, params: { outreach: { phone: "+15550009999", template_id: message_templates(:quote_follow_up).id, template_params: [ "Zara", "panels" ] } }
    end
    assert_redirected_to Conversation.last
  end

  test "sends a template when the reply window has closed" do
    conversation = conversations(:ali_open)
    conversation.update!(last_inbound_at: 2.days.ago)

    get conversation_path(conversation)
    assert_select "select[name='outreach[template_id]']"

    assert_difference -> { conversation.messages.count } do
      post conversation_messages_path(conversation), params: { outreach: { template_id: message_templates(:quote_follow_up).id, template_params: [ "Ali", "inverter" ] } }
    end
    assert conversation.messages.last.template?
  end

  test "free-form replies are blocked once the window has closed" do
    conversation = conversations(:ali_open)
    conversation.update!(last_inbound_at: 2.days.ago)

    assert_no_difference -> { conversation.messages.count } do
      post conversation_messages_path(conversation), params: { message: { body: "Hello?" } }
    end
  end
end
