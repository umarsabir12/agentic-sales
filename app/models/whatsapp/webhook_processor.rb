# Turns a WhatsApp Cloud API webhook payload into contacts, conversations and messages.
class Whatsapp::WebhookProcessor
  STATUS_MAP = { "sent" => :sent, "delivered" => :delivered, "read" => :read, "failed" => :failed }.freeze

  def initialize(payload)
    @payload = payload
  end

  def process
    Array(@payload["entry"]).each do |entry|
      Array(entry["changes"]).each do |change|
        value = change["value"] || {}

        case change["field"]
        when "messages"
          profiles = Array(value["contacts"]).to_h { |c| [ c["wa_id"], c.dig("profile", "name") ] }
          Array(value["messages"]).each { |message| receive_message(message, profiles[message["from"]]) }
          Array(value["statuses"]).each { |status| update_status(status) }
        when "message_template_status_update"
          update_template_status(value)
        end
      end
    end
  end

  private
    def receive_message(data, profile_name)
      return if Message.exists?(wa_message_id: data["id"])

      contact = Contact.find_or_create_by!(phone: data["from"])
      contact.update!(profile_name: profile_name) if profile_name.present? && contact.profile_name != profile_name

      conversation = contact.current_conversation || contact.conversations.create!

      conversation.messages.create!(
        direction: :inbound,
        sender_type: :customer,
        wa_message_id: data["id"],
        body: body_for(data),
        delivery_status: :delivered,
        sent_at: Time.zone.at(data["timestamp"].to_i)
      )
    rescue ActiveRecord::RecordNotUnique
      # Meta delivered the same message twice concurrently; the first one won.
    end

    def update_status(data)
      message = Message.find_by(wa_message_id: data["id"])
      new_status = STATUS_MAP[data["status"]]
      return unless message && new_status
      # Statuses can arrive out of order; never move backwards (e.g. read -> delivered).
      return if Message.delivery_statuses[new_status.to_s] < Message.delivery_statuses[message.delivery_status]

      message.update!(delivery_status: new_status, error_message: error_text(data.dig("errors", 0)))
    end

    def update_template_status(data)
      template = MessageTemplate.find_by(wa_template_id: data["message_template_id"].to_s) ||
        MessageTemplate.find_by(name: data["message_template_name"], language: data["message_template_language"])
      return unless template && data["event"].present?

      reason = data["reason"] unless data["reason"].in?([ nil, "", "NONE" ])
      template.update!(status: data["event"], rejected_reason: reason, synced_at: Time.current)
    end

    def error_text(error)
      return if error.blank?

      text = [ error["title"] || error["message"], ("(code #{error["code"]})" if error["code"]) ].compact.join(" ")
      details = error.dig("error_data", "details")
      details.present? && details != text ? "#{text}: #{details}" : text
    end

    def body_for(data)
      case data["type"]
      when "text" then data.dig("text", "body")
      when "button" then data.dig("button", "text")
      when "interactive" then data.dig("interactive", "button_reply", "title") || data.dig("interactive", "list_reply", "title")
      when "location" then "[Location] #{data.dig("location", "name") || "#{data.dig("location", "latitude")}, #{data.dig("location", "longitude")}"}"
      else
        caption = data.dig(data["type"], "caption")
        [ "[#{data["type"].to_s.humanize}]", caption ].compact.join(" ")
      end.presence || "[Unsupported message]"
    end
end
