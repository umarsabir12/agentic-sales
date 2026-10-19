require "test_helper"

class SalesAgentTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:ali_open)
    AgentSetting.current.update!(business_name: "Tronsit Solar", instructions: "We sell 5kW inverters for PKR 300,000.")
  end

  test "returns Claude's reply and sends the conversation as alternating turns" do
    SalesAgent.client = client = FakeAnthropicClient.new([ FakeAnthropicClient.text("Yes, the 5kW is in stock!") ])
    @conversation.messages.create!(direction: :outbound, sender_type: :ai, body: "Hi! How can I help?", delivery_status: :sent)
    @conversation.messages.create!(direction: :inbound, sender_type: :customer, body: "Is it in stock?")

    assert_equal "Yes, the 5kW is in stock!", SalesAgent.new(@conversation).reply

    request = client.requests.first
    assert_equal "claude-opus-5-5", request[:model]
    assert_equal :default, request[:fallbacks]
    assert_includes request[:betas], "server-side-fallback-2026-07-01"
    assert_equal %i[ user assistant user ], request[:messages].map { |m| m[:role] }
    assert_match "PKR 300,000", request[:system_].first[:text]
  end

  test "creates a ticket, then updates the same ticket on a later call" do
    tickets(:ali_inverter).update!(status: :won)
    ticket_input = { title: "5kW inverter", summary: "Home install", product_interest: "5kW inverter", budget: "300k", priority: "high" }
    SalesAgent.client = client = FakeAnthropicClient.new([
      FakeAnthropicClient.tool("create_sales_ticket", ticket_input), FakeAnthropicClient.text("Great, I've noted that.")
    ])

    assert_difference -> { @conversation.tickets.source_ai.count }, 1 do
      assert_equal "Great, I've noted that.", SalesAgent.new(@conversation).reply
    end
    tool_result = client.requests.last[:messages].last[:content].first
    assert_equal :tool_result, tool_result[:type]
    assert_equal "toolu_create_sales_ticket", tool_result[:tool_use_id]

    SalesAgent.client = FakeAnthropicClient.new([
      FakeAnthropicClient.tool("create_sales_ticket", ticket_input.merge(budget: "350k")), FakeAnthropicClient.text("Updated.")
    ])
    assert_no_difference -> { @conversation.tickets.source_ai.count } do
      SalesAgent.new(@conversation).reply
    end
    assert_equal "350k", @conversation.tickets.source_ai.last.budget
  end

  test "saves the customer's name" do
    SalesAgent.client = FakeAnthropicClient.new([ FakeAnthropicClient.tool("save_customer_name", { "name" => "Ali Raza" }), FakeAnthropicClient.text("Thanks Ali!") ])
    SalesAgent.new(@conversation).reply
    assert_equal "Ali Raza", @conversation.contact.reload.name
  end

  test "hand-off pauses the AI with a reason" do
    SalesAgent.client = FakeAnthropicClient.new([ FakeAnthropicClient.tool("hand_off_to_human", { reason: "Wants a discount" }), FakeAnthropicClient.text("A team member will reply soon.") ])

    assert_equal "A team member will reply soon.", SalesAgent.new(@conversation).reply
    assert @conversation.reload.human_active?
    assert_equal "Wants a discount", @conversation.handoff_reason
  end

  test "a refusal hands the conversation to the team without replying" do
    SalesAgent.client = FakeAnthropicClient.new([ FakeAnthropicClient.refusal ])
    assert_equal "", SalesAgent.new(@conversation).reply
    assert @conversation.reload.human_active?
  end
end
