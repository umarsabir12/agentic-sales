# Lets the AI agent answer a customer's message. Enqueued with a short delay so a burst of
# messages from the customer gets one reply that covers them all.
class AgentReplyJob < ApplicationJob
  queue_as :default

  RETRYABLE = [ Anthropic::Errors::RateLimitError, Anthropic::Errors::InternalServerError, Anthropic::Errors::APIConnectionError ].freeze

  retry_on(*RETRYABLE, wait: :polynomially_longer, attempts: 4) do |job, error|
    job.give_up(error)
  end

  def perform(conversation, trigger_message)
    @conversation = conversation
    return unless should_reply?(trigger_message)

    text = SalesAgent.new(conversation).reply
    conversation.reload

    # The team may have stepped in, or the customer written again, while Claude was thinking.
    return if text.blank? || newer_inbound?(trigger_message) || conversation.closed?
    return if conversation.human_active? && conversation.messages.sent_by_staff.where("id > ?", trigger_message.id).exists?

    conversation.messages.create!(direction: :outbound, sender_type: :ai, body: text)
  rescue *RETRYABLE
    raise # handled by retry_on
  rescue Anthropic::Errors::Error => e
    give_up(e)
  end

  # The customer must not be left waiting silently: hand the chat to the team.
  def give_up(error)
    Rails.logger.error("[AgentReplyJob] #{error.class}: #{error.message}")
    conversation = @conversation || arguments.first
    conversation.hand_off!("The AI agent couldn't reply (#{error.class.name.demodulize}). Please answer the customer.") unless conversation.closed?
  end

  private
    def should_reply?(trigger_message)
      settings = AgentSetting.current
      @conversation.reload
      settings.enabled && SalesAgent.configured? && @conversation.ai_active? &&
        @conversation.messages.last == trigger_message && trigger_message.inbound?
    end

    def newer_inbound?(trigger_message)
      @conversation.messages.inbound.where("id > ?", trigger_message.id).exists?
    end
end
