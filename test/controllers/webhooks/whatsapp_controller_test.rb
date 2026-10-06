require "test_helper"

class Webhooks::WhatsappControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ENV["WHATSAPP_VERIFY_TOKEN"] = "verify-me"
    ENV["WHATSAPP_APP_SECRET"] = "app-secret"
  end

  teardown do
    ENV.delete("WHATSAPP_VERIFY_TOKEN")
    ENV.delete("WHATSAPP_APP_SECRET")
  end

  test "completes the subscription handshake" do
    get webhooks_whatsapp_path, params: { "hub.mode" => "subscribe", "hub.verify_token" => "verify-me", "hub.challenge" => "12345" }
    assert_response :success
    assert_equal "12345", response.body
  end

  test "rejects a wrong verify token" do
    get webhooks_whatsapp_path, params: { "hub.mode" => "subscribe", "hub.verify_token" => "nope", "hub.challenge" => "12345" }
    assert_response :forbidden
  end

  test "rejects events without a valid signature" do
    post webhooks_whatsapp_path, params: "{}", headers: { "Content-Type" => "application/json", "X-Hub-Signature-256" => "sha256=bad" }
    assert_response :unauthorized
  end

  test "accepts signed events and processes them in a job" do
    body = { object: "whatsapp_business_account", entry: [] }.to_json
    signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "app-secret", body)

    assert_enqueued_with(job: WhatsappWebhookJob) do
      post webhooks_whatsapp_path, params: body, headers: { "Content-Type" => "application/json", "X-Hub-Signature-256" => signature }
    end
    assert_response :success
  end
end
