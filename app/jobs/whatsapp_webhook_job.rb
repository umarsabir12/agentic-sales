class WhatsappWebhookJob < ApplicationJob
  queue_as :default

  def perform(payload)
    Whatsapp::WebhookProcessor.new(payload).process
  end
end
