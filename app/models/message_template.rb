# A WhatsApp message template. Templates are created on the WhatsApp Business Account and
# must be approved by Meta before they can be sent. They are the only way to message a
# customer outside the 24-hour customer service window.
class MessageTemplate < ApplicationRecord
  CATEGORIES = %w[ MARKETING UTILITY ].freeze
  LANGUAGES = {
    "en_US" => "English (US)", "en_GB" => "English (UK)", "en" => "English", "ur" => "Urdu",
    "ar" => "Arabic", "hi" => "Hindi", "es" => "Spanish", "fr" => "French", "de" => "German", "pt_BR" => "Portuguese (BR)"
  }.freeze
  VARIABLE = /\{\{(\d+)\}\}/
  MAX_QUICK_REPLIES = 3

  normalizes :name, with: ->(n) { n.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") }

  validates :name, presence: true, length: { maximum: 512 }, uniqueness: { scope: :language }
  validates :language, presence: true
  validates :category, presence: true
  validates :body, presence: true, length: { maximum: 1024 }
  validates :header_text, length: { maximum: 60 }
  validates :footer, length: { maximum: 60 }
  validate :header_has_no_variables, :variables_are_sequential, :examples_match_variables, :buttons_are_valid, on: :submit

  scope :approved, -> { where(status: "APPROVED") }
  scope :alphabetical, -> { order(:name, :language) }

  # --- Status ---

  def approved? = status == "APPROVED"
  def pending? = status.in?(%w[ PENDING IN_APPEAL ])
  def rejected? = status == "REJECTED"
  def draft? = status == "DRAFT"

  SUPPORTED_COMPONENTS = %w[ HEADER BODY FOOTER BUTTONS ].freeze
  STATIC_BUTTONS = %w[ QUICK_REPLY URL PHONE_NUMBER ].freeze

  # The portal can send templates whose only variables are in the body: text or no header,
  # and buttons that need no parameters. Carousels, media headers, copy-code buttons etc. aren't supported yet.
  def sendable?
    approved? && components.all? { |c| c["type"].in?(SUPPORTED_COMPONENTS) } &&
      header_format.in?([ nil, "TEXT" ]) && !header_text.to_s.match?(VARIABLE) &&
      buttons.all? { |b| b["type"].in?(STATIC_BUTTONS) && !b["url"].to_s.match?(VARIABLE) }
  end

  # --- Variables ---

  def variable_count
    body.to_s.scan(VARIABLE).flatten.map(&:to_i).max.to_i
  end

  def render(params = [])
    text = body.to_s.gsub(VARIABLE) { params[$1.to_i - 1].presence || "{{#{$1}}}" }
    [ header_text.presence, text, footer.presence ].compact.join("\n\n")
  end

  # --- Buttons (stored as [{ "type" => "QUICK_REPLY" | "URL", "text" => ..., "url" => ... }]) ---

  def quick_replies
    buttons.select { |b| b["type"] == "QUICK_REPLY" }.map { |b| b["text"] }
  end

  def quick_replies=(lines)
    replies = lines.to_s.lines.map(&:strip).compact_blank.map { |text| { "type" => "QUICK_REPLY", "text" => text } }
    self.buttons = replies + buttons.select { |b| b["type"] == "URL" }
  end

  def url_button
    buttons.find { |b| b["type"] == "URL" } || {}
  end

  def url_button=(attrs)
    attrs = attrs.to_h.stringify_keys.slice("text", "url").transform_values(&:strip)
    url = attrs.values.all?(&:present?) ? [ attrs.merge("type" => "URL") ] : []
    self.buttons = buttons.reject { |b| b["type"] == "URL" } + url
  end

  def body_examples=(values)
    super(Array(values).map(&:to_s).map(&:strip))
  end

  # --- Meta API format ---

  def components_payload
    components = []
    components << { type: "HEADER", format: "TEXT", text: header_text } if header_text.present?

    body_component = { type: "BODY", text: body }
    body_component[:example] = { body_text: [ body_examples.first(variable_count) ] } if variable_count.positive?
    components << body_component

    components << { type: "FOOTER", text: footer } if footer.present?
    components << { type: "BUTTONS", buttons: buttons.map { |b| b.symbolize_keys.compact } } if buttons.any?
    components
  end

  def submit!
    return false unless valid?(:submit)

    response = Whatsapp.client.create_template(name: name, language: language, category: category, components: components_payload)
    update!(wa_template_id: response["id"], status: response["status"] || "PENDING", category: response["category"] || category, rejected_reason: nil, synced_at: Time.current)
  rescue Whatsapp::Client::Error => e
    errors.add(:base, "Meta rejected the template: #{e.message}")
    false
  end

  def delete_remotely!
    Whatsapp.client.delete_template(name: name, wa_template_id: wa_template_id) unless draft?
    destroy!
  end

  # Pulls every template from the WhatsApp Business Account and mirrors it locally.
  def self.sync!
    remote = Whatsapp.client.list_templates
    synced_ids = remote.map { |data| from_api(data).id }
    where.not(id: synced_ids).where.not(status: "DRAFT").destroy_all
    remote.size
  end

  def self.from_api(data)
    components = Array(data["components"]).index_by { |c| c["type"] }
    header = components["HEADER"] || {}
    body = components["BODY"] || {}

    template = find_by(wa_template_id: data["id"]) || find_or_initialize_by(name: data["name"], language: data["language"])
    template.update!(
      wa_template_id: data["id"],
      category: data["category"],
      status: data["status"],
      rejected_reason: (data["rejected_reason"] if data["rejected_reason"].present? && data["rejected_reason"] != "NONE"),
      header_format: header["format"],
      header_text: header["text"],
      body: body["text"].presence || "(empty)",
      body_examples: Array(body.dig("example", "body_text", 0)),
      footer: components.dig("FOOTER", "text"),
      buttons: Array(components.dig("BUTTONS", "buttons")).map { |b| b.slice("type", "text", "url") },
      components: Array(data["components"]),
      synced_at: Time.current
    )
    template
  end

  private
    def header_has_no_variables
      errors.add(:header_text, "can't contain variables") if header_text.to_s.match?(VARIABLE)
    end

    def variables_are_sequential
      numbers = body.to_s.scan(VARIABLE).flatten.map(&:to_i).uniq.sort
      errors.add(:body, "variables must be numbered {{1}}, {{2}}, … without gaps") unless numbers == (1..numbers.size).to_a
    end

    def examples_match_variables
      return if variable_count.zero?

      if body_examples.first(variable_count).count(&:present?) < variable_count
        errors.add(:body_examples, "need a sample value for each of the #{variable_count} variables (Meta requires them for review)")
      end
    end

    def buttons_are_valid
      errors.add(:quick_replies, "can have at most #{MAX_QUICK_REPLIES} buttons") if quick_replies.size > MAX_QUICK_REPLIES
      errors.add(:quick_replies, "must be 25 characters or less") if quick_replies.any? { |t| t.length > 25 }
      if url_button.present? && !url_button["url"].to_s.match?(%r{\Ahttps?://})
        errors.add(:url_button, "URL must start with http:// or https://")
      end
    end
end
