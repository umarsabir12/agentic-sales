require "test_helper"

class MessageTemplateTest < ActiveSupport::TestCase
  def build(**attrs)
    MessageTemplate.new({ name: "Quote Ready", language: "en_US", category: "UTILITY", body: "Hi {{1}}, about {{2}}", body_examples: [ "Ali", "solar" ] }.merge(attrs))
  end

  test "normalizes the name to Meta's format" do
    assert_equal "quote_ready", build.name
  end

  test "counts variables and renders values" do
    template = message_templates(:quote_follow_up)
    assert_equal 2, template.variable_count
    assert_equal "Hi Sara, your quote for panels is ready. Reply YES and we'll call you.", template.render([ "Sara", "panels" ])
  end

  test "builds Meta components with examples and buttons" do
    template = build(header_text: "Quote", footer: "Thanks", quick_replies: "Yes\nNo", url_button: { text: "Details", url: "https://example.com" })
    components = template.components_payload

    assert_equal %w[ HEADER BODY FOOTER BUTTONS ], components.map { |c| c[:type] }
    assert_equal [ [ "Ali", "solar" ] ], components[1][:example][:body_text]
    assert_equal [ "QUICK_REPLY", "QUICK_REPLY", "URL" ], components[3][:buttons].map { |b| b[:type] }
  end

  test "rejects variables with gaps, missing samples and variable headers" do
    assert_not build(body: "Hi {{1}} and {{3}}", body_examples: %w[ a b c ]).valid?(:submit)
    assert_not build(body_examples: [ "Ali" ]).valid?(:submit)
    assert_not build(header_text: "Hi {{1}}").valid?(:submit)
    assert_not build(quick_replies: "a\nb\nc\nd").valid?(:submit)
    assert build.valid?(:submit)
  end

  test "submit! creates the template on Meta and saves it as pending" do
    Whatsapp.client = client = FakeWhatsappClient.new
    template = build

    assert template.submit!
    assert template.persisted?
    assert template.pending?
    assert_equal "tmpl_quote_ready", template.wa_template_id
    assert_equal "quote_ready", client.calls_to(:create_template).first[:name]
  end

  test "submit! reports Meta's error without saving" do
    Whatsapp.client = FakeWhatsappClient.new(error: "Template name already exists")
    template = build

    assert_not template.submit!
    assert_not template.persisted?
    assert_match "Template name already exists", template.errors.full_messages.to_sentence
  end

  test "sync! mirrors Meta's templates and removes deleted ones" do
    Whatsapp.client = FakeWhatsappClient.new(templates: [
      { "id" => "1001", "name" => "quote_follow_up", "language" => "en_US", "status" => "APPROVED", "category" => "UTILITY",
        "components" => [ { "type" => "BODY", "text" => "Updated {{1}}", "example" => { "body_text" => [ [ "Ali" ] ] } } ] },
      { "id" => "2000", "name" => "hello_world", "language" => "en_US", "status" => "APPROVED", "category" => "UTILITY",
        "components" => [ { "type" => "HEADER", "format" => "TEXT", "text" => "Hello World" }, { "type" => "BODY", "text" => "Welcome!" },
                          { "type" => "FOOTER", "text" => "Sample footer" } ] }
    ])

    assert_equal 2, MessageTemplate.sync!

    assert_equal "Updated {{1}}", message_templates(:quote_follow_up).reload.body
    hello = MessageTemplate.find_by!(name: "hello_world")
    assert_equal "Hello World", hello.header_text
    assert hello.sendable?
    assert_not MessageTemplate.exists?(name: "pending_promo")
  end

  test "media headers are not sendable yet" do
    assert_not build(status: "APPROVED", header_format: "IMAGE").sendable?
  end

  test "carousels and copy-code buttons are not sendable yet" do
    assert_not build(status: "APPROVED", components: [ { "type" => "BODY" }, { "type" => "CAROUSEL" } ]).sendable?
    assert_not build(status: "APPROVED", buttons: [ { "type" => "COPY_CODE", "text" => "Copy" } ]).sendable?
  end
end
