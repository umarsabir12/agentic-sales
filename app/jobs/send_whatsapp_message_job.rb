class SendWhatsappMessageJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, wait: :polynomially_longer, attempts: 5

  def perform(message)
    return unless message.outbound? && message.pending?

    to = message.conversation.contact.phone
    wa_message_id =
      if message.template?
        Whatsapp.client.send_template(to: to, name: message.template_name, language: message.template_language, body_params: message.template_params)
      else
        Whatsapp.client.send_text(to: to, body: message.body)
      end
    message.update!(wa_message_id: wa_message_id, delivery_status: :sent, sent_at: Time.current, error_message: nil)
  rescue Whatsapp::Client::Error => e
    message.update!(delivery_status: :failed, error_message: e.message)
  end
end
