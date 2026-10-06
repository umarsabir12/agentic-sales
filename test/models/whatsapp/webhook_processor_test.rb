require "test_helper"

class Whatsapp::WebhookProcessorTest < ActiveSupport::TestCase
  def payload(value)
    { "object" => "whatsapp_business_account", "entry" => [ { "id" => "WABA", "changes" => [ { "field" => "messages", "value" => value } ] } ] }
  end

  def text_message(id:, from:, body:)
    payload(
      "contacts" => [ { "wa_id" => from, "profile" => { "name" => "New Customer" } } ],
      "messages" => [ { "id" => id, "from" => from, "timestamp" => Time.current.to_i.to_s, "type" => "text", "text" => { "body" => body } } ]
    )
  end

  test "creates contact, conversation and message for a new customer" do
    assert_difference -> { Contact.count } => 1, -> { Conversation.count } => 1, -> { Message.count } => 1 do
      Whatsapp::WebhookProcessor.new(text_message(id: "wamid.1", from: "15551234567", body: "Hello")).process
    end

    contact = Contact.find_by!(phone: "15551234567")
    assert_equal "New Customer", contact.profile_name
    message = contact.conversations.last.messages.last
    assert message.inbound?
    assert_equal "Hello", message.body
  end

  test "adds to the existing open conversation" do
    assert_no_difference "Conversation.count" do
      Whatsapp::WebhookProcessor.new(text_message(id: "wamid.2", from: contacts(:ali).phone, body: "Any update?")).process
    end
    assert_equal "Any update?", conversations(:ali_open).messages.last.body
  end

  test "ignores duplicate deliveries" do
    event = text_message(id: "wamid.3", from: "15551234567", body: "Hello")
    Whatsapp::WebhookProcessor.new(event).process

    assert_no_difference "Message.count" do
      Whatsapp::WebhookProcessor.new(event).process
    end
  end

  test "describes media messages" do
    event = payload("messages" => [ { "id" => "wamid.4", "from" => "15551234567", "timestamp" => "0", "type" => "image", "image" => { "caption" => "my roof" } } ])
    Whatsapp::WebhookProcessor.new(event).process
    assert_equal "[Image] my roof", Message.find_by!(wa_message_id: "wamid.4").body
  end

  test "updates delivery status without moving backwards" do
    message = conversations(:ali_open).messages.create!(direction: :outbound, sender_type: :ai, body: "Hi", wa_message_id: "wamid.out", delivery_status: :sent)

    Whatsapp::WebhookProcessor.new(payload("statuses" => [ { "id" => "wamid.out", "status" => "read" } ])).process
    assert message.reload.read?

    Whatsapp::WebhookProcessor.new(payload("statuses" => [ { "id" => "wamid.out", "status" => "delivered" } ])).process
    assert message.reload.read?
  end

  test "updates template status from Meta's review" do
    event = { "entry" => [ { "changes" => [ { "field" => "message_template_status_update",
      "value" => { "event" => "REJECTED", "message_template_id" => 1002, "message_template_name" => "pending_promo", "message_template_language" => "en_US", "reason" => "INCORRECT_CATEGORY" } } ] } ] }

    Whatsapp::WebhookProcessor.new(event).process

    template = message_templates(:pending_promo).reload
    assert template.rejected?
    assert_equal "INCORRECT_CATEGORY", template.rejected_reason
  end
end
