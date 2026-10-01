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
end
