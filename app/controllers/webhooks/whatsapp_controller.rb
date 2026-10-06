# Receives WhatsApp Cloud API webhooks from Meta. Public endpoint: authenticity is checked
# with the verify token (subscription handshake) and the X-Hub-Signature-256 header (events).
class Webhooks::WhatsappController < ActionController::API
  def verify
    if params["hub.mode"] == "subscribe" && valid_verify_token?(params["hub.verify_token"])
      render plain: params["hub.challenge"]
    else
      head :forbidden
    end
  end

  def receive
    return head :unauthorized unless valid_signature?

    WhatsappWebhookJob.perform_later(JSON.parse(request.raw_post))
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private
    def valid_verify_token?(token)
      expected = Whatsapp.config.verify_token
      expected.present? && token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
    end

    def valid_signature?
      secret = Whatsapp.config.app_secret
      signature = request.headers["X-Hub-Signature-256"].to_s
      return false if secret.blank? || signature.blank?

      expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
      ActiveSupport::SecurityUtils.secure_compare(signature, expected)
    end
end
