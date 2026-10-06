# Sends an approved template message, either to a new/known phone number (starting a
# conversation) or inside an existing conversation whose 24-hour window has closed.
class Outreach
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :phone, :string
  attribute :name, :string
  attribute :template_id, :integer
  attribute :template_params, default: -> { [] }

  attr_accessor :conversation, :user
  attr_reader :message

  validates :phone, presence: true, format: { with: /\A\+?[\d\s\-()]{8,20}\z/, message: "must be a full number with country code" }, unless: :conversation
  validates :template, presence: true
  validate :template_is_sendable, :params_are_complete

  def template
    @template ||= MessageTemplate.find_by(id: template_id)
  end

  def template_params=(values)
    super(Array(values).map(&:to_s).map(&:strip))
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      self.conversation ||= find_or_start_conversation
      @message = conversation.messages.create!(
        direction: :outbound, sender_type: :staff, user: user,
        body: template.render(params), template_name: template.name, template_language: template.language, template_params: params
      )
      conversation.take_over!(user) unless conversation.human_active? && conversation.assigned_user == user
    end
    true
  end

  private
    def params
      template_params.first(template.variable_count)
    end

    def find_or_start_conversation
      contact = Contact.find_or_create_by!(phone: Contact.normalize_value_for(:phone, phone))
      contact.update!(name: name) if name.present? && contact.name.blank?
      contact.current_conversation || contact.conversations.create!
    end

    def template_is_sendable
      errors.add(:template_id, "is not approved for sending yet") if template && !template.sendable?
    end

    def params_are_complete
      return unless template

      if params.size < template.variable_count || params.any?(&:blank?)
        errors.add(:template_params, "need a value for each of the #{template.variable_count} variables")
      end
    end
end
