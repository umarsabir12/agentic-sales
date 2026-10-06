require "test_helper"

class OutreachTest < ActiveSupport::TestCase
  test "starts a conversation with a new number" do
    outreach = Outreach.new(phone: "+1 555 000 1234", name: "Zara", template_id: message_templates(:quote_follow_up).id, template_params: [ "Zara", "panels" ], user: users(:agent))

    assert_difference -> { Contact.count } => 1, -> { Conversation.count } => 1, -> { Message.count } => 1 do
      assert outreach.save
    end

    message = outreach.message
    assert_equal "Zara", message.conversation.contact.name
    assert_equal "15550001234", message.conversation.contact.phone
    assert_equal "quote_follow_up", message.template_name
    assert_equal [ "Zara", "panels" ], message.template_params
    assert_match "Hi Zara, your quote for panels", message.body
    assert message.conversation.human_active?
  end

  test "requires a value for every variable" do
    outreach = Outreach.new(phone: "+15550001234", template_id: message_templates(:quote_follow_up).id, template_params: [ "Zara" ], user: users(:agent))
    assert_not outreach.save
    assert outreach.errors[:template_params].any?
  end

  test "rejects templates that aren't approved" do
    outreach = Outreach.new(phone: "+15550001234", template_id: message_templates(:pending_promo).id, user: users(:agent))
    assert_not outreach.save
    assert_includes outreach.errors[:template_id], "is not approved for sending yet"
  end

  test "sends inside an existing conversation" do
    conversation = conversations(:ali_open)
    outreach = Outreach.new(conversation: conversation, template_id: message_templates(:quote_follow_up).id, template_params: [ "Ali", "inverter" ], user: users(:agent))

    assert_no_difference "Conversation.count" do
      assert outreach.save
    end
    assert_equal conversation, outreach.message.conversation
  end
end
