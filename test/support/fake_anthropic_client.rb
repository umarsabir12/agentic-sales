# Stands in for Anthropic::Client in tests: returns scripted responses and records each request.
# Assign with `SalesAgent.client = FakeAnthropicClient.new(responses)`.
class FakeAnthropicClient
  Block = Struct.new(:type, :text, :id, :name, :input, keyword_init: true)
  Response = Struct.new(:content, :stop_reason, keyword_init: true)

  attr_reader :requests

  def self.text(text) = Response.new(content: [ Block.new(type: :text, text: text) ], stop_reason: :end_turn)
  def self.tool(name, input, id: "toolu_#{name}") = Response.new(content: [ Block.new(type: :tool_use, id: id, name: name, input: input) ], stop_reason: :tool_use)
  def self.refusal = Response.new(content: [], stop_reason: :refusal)

  def initialize(responses = [], error: nil)
    @responses = responses.dup
    @error = error
    @requests = []
  end

  def beta = self
  def messages = self

  def create(**params)
    @requests << params
    raise @error if @error

    @responses.shift || self.class.text("(no more scripted responses)")
  end
end
