module Whatsapp
  Config = Data.define(:phone_number_id, :business_account_id, :access_token, :app_secret, :verify_token, :api_version)

  DEFAULT_API_VERSION = "v23.0"

  # Reads WHATSAPP_* environment variables, falling back to Rails credentials (whatsapp.*).
  def self.config
    creds = Rails.application.credentials.whatsapp || {}
    fetch = ->(key) { ENV["WHATSAPP_#{key.upcase}"].presence || creds[key].presence }

    Config.new(
      phone_number_id: fetch.(:phone_number_id),
      business_account_id: fetch.(:business_account_id),
      access_token: fetch.(:access_token),
      app_secret: fetch.(:app_secret),
      verify_token: fetch.(:verify_token),
      api_version: fetch.(:api_version) || DEFAULT_API_VERSION
    )
  end

  # Swappable for tests.
  mattr_writer :client

  def self.client
    @@client ||= Client.new
  end
end
