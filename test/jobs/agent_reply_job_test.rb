require "test_helper"

class AgentReplyJobTest < ActiveJob::TestCase
  setup do
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    @conversation = conversations(:ali_open)
    @message = @conversation.messages.create!(direction: :inbound, sender_type: :customer, body: "Price for 5kW?")
  end

  teardown { ENV.delete("ANTHROPIC_API_KEY") }

  test "sends the AI reply as an outbound message" do
    SalesAgent.client = FakeAnthropicClient.new([ FakeAnthropicClient.text("It's PKR 300,000.") ])

    assert_enqueued_with(job: SendWhatsappMessageJob) do
      AgentReplyJob.perform_now(@conversation, @message)
    end
    reply = @conversation.messages.last
    assert reply.sent_by_ai?
    assert_equal "It's PKR 300,000.", reply.body
  end

  test "waits for the newest message in a burst" do
    SalesAgent.client = client = FakeAnthropicClient.new
    @conversation.messages.create!(direction: :inbound, sender_type: :customer, body: "And delivery?")

    AgentReplyJob.perform_now(@conversation, @message)
    assert_empty client.requests
  end

  test "stays quiet when a person has taken over or the agent is disabled" do
    SalesAgent.client = client = FakeAnthropicClient.new
    @conversation.take_over!(users(:agent))
    AgentReplyJob.perform_now(@conversation, @message)

    @conversation.hand_back_to_ai!
    AgentSetting.current.update!(enabled: false)
    AgentReplyJob.perform_now(@conversation, @message)

    assert_empty client.requests
  end

  test "hands the chat to the team when Claude can't be reached" do
    error = Anthropic::Errors::AuthenticationError.new(url: URI("https://api.anthropic.com"), status: 401, headers: {}, body: nil, request: nil, response: nil, message: "invalid x-api-key")
    SalesAgent.client = FakeAnthropicClient.new(error: error)

    AgentReplyJob.perform_now(@conversation, @message)

    assert @conversation.reload.human_active?
    assert_match "couldn't reply", @conversation.handoff_reason
  end

  test "incoming WhatsApp messages queue the agent" do
    event = { "entry" => [ { "changes" => [ { "field" => "messages", "value" => {
      "messages" => [ { "id" => "wamid.agent", "from" => contacts(:ali).phone, "timestamp" => Time.current.to_i.to_s, "type" => "text", "text" => { "body" => "Hello?" } } ] } } ] } ] }

    assert_enqueued_with(job: AgentReplyJob) do
      Whatsapp::WebhookProcessor.new(event).process
    end
  end
end
