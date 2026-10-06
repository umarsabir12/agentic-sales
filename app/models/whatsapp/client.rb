require "net/http"

# Minimal WhatsApp Cloud API client: https://developers.facebook.com/docs/whatsapp/cloud-api
class Whatsapp::Client
  class Error < StandardError; end

  # --- Messages (sent from our phone number) ---

  def send_text(to:, body:)
    response = post_message(messaging_product: "whatsapp", recipient_type: "individual", to: to, type: "text", text: { preview_url: false, body: body })
    response.dig("messages", 0, "id")
  end

  def send_template(to:, name:, language:, body_params: [])
    template = { name: name, language: { code: language } }
    if body_params.any?
      template[:components] = [ { type: "body", parameters: body_params.map { |text| { type: "text", text: text.to_s } } } ]
    end

    response = post_message(messaging_product: "whatsapp", recipient_type: "individual", to: to, type: "template", template: template)
    response.dig("messages", 0, "id")
  end

  def mark_as_read(wa_message_id)
    post_message(messaging_product: "whatsapp", status: "read", message_id: wa_message_id)
  end

  # --- Message templates (owned by the WhatsApp Business Account) ---

  TEMPLATE_FIELDS = "id,name,language,status,category,components,rejected_reason".freeze

  def list_templates
    templates = []
    response = request(:get, "#{waba_id}/message_templates", query: { fields: TEMPLATE_FIELDS, limit: 100 })

    loop do
      templates.concat(response["data"] || [])
      after = response.dig("paging", "next") && response.dig("paging", "cursors", "after")
      break unless after

      response = request(:get, "#{waba_id}/message_templates", query: { fields: TEMPLATE_FIELDS, limit: 100, after: after })
    end

    templates
  end

  # Returns { "id" => ..., "status" => ..., "category" => ... }
  def create_template(name:, language:, category:, components:)
    request(:post, "#{waba_id}/message_templates", body: { name: name, language: language, category: category, components: components })
  end

  def delete_template(name:, wa_template_id: nil)
    request(:delete, "#{waba_id}/message_templates", query: { name: name, hsm_id: wa_template_id }.compact)
  end

  private
    def post_message(payload)
      request(:post, "#{config.phone_number_id}/messages", body: payload)
    end

    def waba_id
      config.business_account_id.presence || raise(Error, "WhatsApp business_account_id is not configured")
    end

    def config
      Whatsapp.config
    end

    def request(method, path, query: nil, body: nil)
      raise Error, "WhatsApp phone_number_id and access_token are not configured" if config.phone_number_id.blank? || config.access_token.blank?

      uri = URI("https://graph.facebook.com/#{config.api_version}/#{path}")
      uri.query = URI.encode_www_form(query) if query.present?

      request = { get: Net::HTTP::Get, post: Net::HTTP::Post, delete: Net::HTTP::Delete }.fetch(method).new(uri)
      request["Authorization"] = "Bearer #{config.access_token}"
      if body
        request["Content-Type"] = "application/json"
        request.body = body.to_json
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |http| http.request(request) }
      parsed = JSON.parse(response.body) rescue {}

      unless response.is_a?(Net::HTTPSuccess)
        error = parsed["error"] || {}
        Rails.logger.warn("[WhatsApp] #{method.upcase} #{path} failed: HTTP #{response.code} #{error.to_json}")
        message = [ error["error_user_msg"].presence || error["message"] || "HTTP #{response.code}", ("(code #{error["code"]})" if error["code"]) ].compact.join(" ")
        details = error.dig("error_data", "details")
        raise Error, details.present? ? "#{message}: #{details}" : message
      end

      parsed
    end
end
