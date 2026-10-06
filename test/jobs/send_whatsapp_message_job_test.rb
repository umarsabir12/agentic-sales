require "test_helper"

class SendWhatsappMessageJobTest < ActiveJob::TestCase
  def pending_message(**attrs)
    conversations(:ali_open).messages.create!(direction: :outbound, sender_type: :staff, user: users(:agent), body: "Hello Ali", **attrs)
  end

  test "outbound pending messages are queued for sending" do
    assert_enqueued_with(job: SendWhatsappMessageJob) { pending_message }
  end

  test "sends a text message and stores the WhatsApp id" do
    Whatsapp.client = client = FakeWhatsappClient.new
    message = pending_message

    SendWhatsappMessageJob.perform_now(message)

    assert_equal [ { to: "923001234567", body: "Hello Ali" } ], client.calls_to(:send_text)
    assert message.reload.sent?
    assert message.wa_message_id.present?
  end

  test "sends a template message with its parameters" do
    Whatsapp.client = client = FakeWhatsappClient.new
    message = pending_message(template_name: "quote_follow_up", template_language: "en_US", template_params: [ "Ali", "an inverter" ])

    SendWhatsappMessageJob.perform_now(message)

    assert_equal [ { to: "923001234567", name: "quote_follow_up", language: "en_US", body_params: [ "Ali", "an inverter" ] } ], client.calls_to(:send_template)
    assert message.reload.sent?
  end

  test "marks the message failed when WhatsApp rejects it" do
    Whatsapp.client = FakeWhatsappClient.new(error: "Re-engagement message (code 131047)")
    message = pending_message

    SendWhatsappMessageJob.perform_now(message)

    assert message.reload.failed?
    assert_equal "Re-engagement message (code 131047)", message.error_message
  end
end
