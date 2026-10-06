require "test_helper"

class MessageTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "everyone can list and view templates" do
    sign_in users(:agent)
    get message_templates_path
    assert_response :success
    get message_template_path(message_templates(:quote_follow_up))
    assert_response :success
  end

  test "only admins can create templates" do
    sign_in users(:agent)
    get new_message_template_path
    assert_redirected_to message_templates_path
  end

  test "admins submit new templates to Meta" do
    Whatsapp.client = FakeWhatsappClient.new
    sign_in users(:admin)

    get new_message_template_path
    assert_response :success

    assert_difference "MessageTemplate.count" do
      post message_templates_path, params: { message_template: { name: "order_update", language: "en_US", category: "UTILITY", body: "Hi {{1}}", body_examples: [ "Ali" ] } }
    end
    assert_redirected_to MessageTemplate.last
  end

  test "sync imports templates from Meta" do
    Whatsapp.client = FakeWhatsappClient.new(templates: [ { "id" => "9", "name" => "hello_world", "language" => "en_US", "status" => "APPROVED", "category" => "UTILITY", "components" => [ { "type" => "BODY", "text" => "Hi" } ] } ])
    sign_in users(:agent)

    post sync_message_templates_path
    assert_redirected_to message_templates_path
    assert MessageTemplate.exists?(name: "hello_world")
  end

  test "admins delete templates on Meta" do
    Whatsapp.client = client = FakeWhatsappClient.new
    sign_in users(:admin)

    delete message_template_path(message_templates(:quote_follow_up))
    assert_redirected_to message_templates_path
    assert_equal "quote_follow_up", client.calls_to(:delete_template).first[:name]
  end
end
