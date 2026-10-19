# The AI sales agent: reads a WhatsApp conversation, asks Claude for the next reply, and
# runs the tools Claude calls (tickets, customer name, hand-off to a human).
class SalesAgent
  MODEL = "claude-opus-5-5"
  MAX_TOOL_ROUNDS = 6
  HISTORY_LIMIT = 40
  BETAS = [ "server-side-fallback-2026-07-01" ].freeze

  BASE_INSTRUCTIONS = <<~PROMPT.freeze
    You are the WhatsApp sales assistant for the business described below. You talk directly with
    customers who message the business on WhatsApp.

    How to reply:
    - Write like a helpful salesperson on WhatsApp: short, warm, plain text. Two to four sentences is
      usually enough. WhatsApp formatting only (*bold*, _italic_); no markdown headings, tables or links
      in markdown syntax.
    - Reply in the language the customer writes in.
    - Only state facts about products, prices, stock, delivery or policies that appear in the business
      information. If you don't know, say a team member will confirm, and hand the conversation off.
    - Ask one question at a time to understand what the customer needs.

    Tools:
    - When the customer shows buying interest (asks for a quote, price for a quantity, availability,
      a visit or a call, or says they want to buy), call create_sales_ticket with what you know. Call it
      again later to update the same ticket as you learn more (budget, product, quantity, timing).
    - When the customer tells you their name, call save_customer_name.
    - Call hand_off_to_human when the customer asks for a person, is upset, wants to negotiate or
      confirm an order or payment, or asks something you can't answer from the business information.
      After handing off, tell the customer briefly that a team member will reply soon.
    - Never mention tools, tickets or that you are handing off "a conversation"; speak naturally.
  PROMPT

  TOOLS = [
    {
      name: "create_sales_ticket",
      description: "Create or update the sales ticket (lead) for this customer so the sales team can follow up. " \
                   "Use when the customer shows buying interest; call again to update it with new details.",
      strict: true,
      input_schema: {
        type: "object",
        properties: {
          title: { type: "string", description: "Short lead title, e.g. '5kW inverter for home install'" },
          summary: { type: "string", description: "What the customer wants, key details and agreed next step" },
          product_interest: { type: "string", description: "Product or service they are interested in, or empty" },
          budget: { type: "string", description: "Budget as the customer said it, or empty" },
          priority: { type: "string", enum: %w[ low medium high urgent ], description: "urgent = ready to buy now" }
        },
        required: %w[ title summary product_interest budget priority ],
        additionalProperties: false
      }
    },
    {
      name: "save_customer_name",
      description: "Save the customer's name when they tell you what it is.",
      strict: true,
      input_schema: {
        type: "object",
        properties: { name: { type: "string" } },
        required: %w[ name ],
        additionalProperties: false
      }
    },
    {
      name: "hand_off_to_human",
      description: "Pause the AI on this conversation and alert the sales team to reply personally.",
      strict: true,
      input_schema: {
        type: "object",
        properties: { reason: { type: "string", description: "Why a person is needed, for the team" } },
        required: %w[ reason ],
        additionalProperties: false
      }
    }
  ].freeze

  # Swappable for tests.
  mattr_writer :client

  def self.client
    @@client ||= Anthropic::Client.new(api_key: api_key)
  end

  def self.api_key
    ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.dig(:anthropic, :api_key)
  end

  def self.configured?
    api_key.present?
  end

  attr_reader :conversation, :settings

  def initialize(conversation, settings: AgentSetting.current)
    @conversation = conversation
    @settings = settings
  end

  # Returns the reply text to send to the customer (may be blank).
  def reply
    messages = transcript
    text_parts = []

    MAX_TOOL_ROUNDS.times do
      response = request(messages)
      text_parts.concat(response.content.select { |block| block.type == :text }.map(&:text))

      case response.stop_reason
      when :tool_use
        messages << assistant_turn(response)
        messages << { role: :user, content: run_tools(response) }
      when :refusal
        conversation.hand_off!("The AI declined to answer this conversation")
        return ""
      else
        break
      end
    end

    text_parts.join("\n\n").strip
  end

  private
    def request(messages)
      self.class.client.beta.messages.create(
        model: MODEL,
        max_tokens: 16_000,
        output_config: { effort: settings.effort },
        system_: system_prompt,
        tools: TOOLS,
        messages: messages,
        betas: BETAS,
        fallbacks: :default
      )
    end

    # Stable business instructions first (cached), conversation-specific context after.
    def system_prompt
      business = settings.business_name.presence || "this business"
      [
        { type: "text", text: "#{BASE_INSTRUCTIONS}\nBusiness: #{business}\n\nBusiness information:\n#{settings.instructions.presence || "(none provided yet)"}",
          cache_control: { type: "ephemeral" } },
        { type: "text", text: context_note }
      ]
    end

    def context_note
      contact = conversation.contact
      tickets = conversation.tickets.active.map { |t| "- #{t.title} (#{t.status.humanize}, #{t.priority} priority)" }
      <<~NOTE
        Current time: #{Time.current.strftime("%A %-d %B %Y, %H:%M %Z")}
        Customer: #{contact.name.presence || "name unknown"}#{" (WhatsApp profile: #{contact.profile_name})" if contact.profile_name.present?}
        Open tickets for this conversation:
        #{tickets.any? ? tickets.join("\n") : "none"}
      NOTE
    end

    # WhatsApp history as alternating user/assistant turns.
    def transcript
      turns = conversation.messages.includes(:user).last(HISTORY_LIMIT).filter_map do |message|
        if message.inbound?
          [ :user, message.body ]
        elsif message.sent_by_staff?
          [ :assistant, "[Sent by #{message.user&.name || "a team member"}]\n#{message.body}" ]
        elsif !message.failed?
          [ :assistant, message.body ]
        end
      end

      merged = turns.chunk_while { |a, b| a.first == b.first }.map do |group|
        { role: group.first.first, content: group.map(&:last).join("\n\n") }
      end
      merged.unshift({ role: :user, content: "[The business started this WhatsApp conversation.]" }) if merged.first&.dig(:role) != :user
      merged
    end

    # Replays Claude's turn unchanged (thinking blocks included); tool calls are re-sent as plain hashes.
    def assistant_turn(response)
      content = response.content.map do |block|
        block.type == :tool_use ? { type: :tool_use, id: block.id, name: block.name, input: block.input } : block
      end
      { role: :assistant, content: content }
    end

    def run_tools(response)
      response.content.select { |block| block.type == :tool_use }.map do |call|
        input = call.input.to_h.transform_keys(&:to_s)
        result = public_send_tool(call.name, input)
        { type: :tool_result, tool_use_id: call.id, content: result }
      rescue StandardError => e
        Rails.logger.warn("[SalesAgent] tool #{call.name} failed: #{e.class}: #{e.message}")
        { type: :tool_result, tool_use_id: call.id, content: "Error: #{e.message}", is_error: true }
      end
    end

    def public_send_tool(name, input)
      case name
      when "create_sales_ticket" then create_sales_ticket(input)
      when "save_customer_name" then save_customer_name(input)
      when "hand_off_to_human" then hand_off_to_human(input)
      else raise ArgumentError, "unknown tool #{name}"
      end
    end

    def create_sales_ticket(input)
      attrs = {
        title: input["title"].to_s.truncate(120), summary: input["summary"],
        product_interest: input["product_interest"].presence, budget: input["budget"].presence,
        priority: input["priority"].presence_in(Ticket.priorities.keys) || "medium"
      }
      ticket = conversation.tickets.active.where(source: :ai).order(:created_at).last

      if ticket
        ticket.update!(attrs)
        "Updated ticket ##{ticket.id}."
      else
        ticket = conversation.tickets.create!(attrs.merge(contact: conversation.contact, source: :ai))
        "Created ticket ##{ticket.id}. The sales team can see it."
      end
    end

    def save_customer_name(input)
      name = input["name"].to_s.strip.truncate(80)
      return "No name given." if name.blank?

      conversation.contact.update!(name: name)
      "Saved the customer's name as #{name}."
    end

    def hand_off_to_human(input)
      conversation.hand_off!(input["reason"].to_s.truncate(250))
      "The sales team has been alerted. Tell the customer a team member will reply soon, then stop."
    end
end
