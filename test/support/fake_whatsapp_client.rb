# Stands in for Whatsapp::Client so tests never call Meta. Assign with `Whatsapp.client = FakeWhatsappClient.new`.
class FakeWhatsappClient
  attr_reader :calls
  attr_accessor :templates, :error

  def initialize(templates: [], error: nil)
    @templates = templates
    @error = error
    @calls = []
  end

  def send_text(**args) = record(:send_text, args) { "wamid.text#{calls.size}" }
  def send_template(**args) = record(:send_template, args) { "wamid.template#{calls.size}" }
  def list_templates = record(:list_templates, {}) { templates }
  def create_template(**args) = record(:create_template, args) { { "id" => "tmpl_#{args[:name]}", "status" => "PENDING", "category" => args[:category] } }
  def delete_template(**args) = record(:delete_template, args) { { "success" => true } }

  def calls_to(name) = calls.select { |c| c[:name] == name }.map { |c| c[:args] }

  private
    def record(name, args)
      calls << { name: name, args: args }
      raise Whatsapp::Client::Error, error if error
      yield
    end
end
