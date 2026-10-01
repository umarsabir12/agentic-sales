class Conversation < ApplicationRecord
  # WhatsApp only allows free-form replies within 24 hours of the customer's last message.
  SERVICE_WINDOW = 24.hours

  belongs_to :contact
  belongs_to :assigned_user, class_name: "User", optional: true
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
  has_many :tickets, dependent: :nullify

  enum :status, { ai_active: 0, human_active: 1, closed: 2 }, default: :ai_active

  scope :recent, -> { order(Arel.sql("last_message_at DESC NULLS LAST")) }
  scope :open, -> { where.not(status: :closed) }

  after_create_commit -> { broadcast_prepend_later_to :conversations, target: "conversations" }
  after_update_commit -> { broadcast_replace_later_to :conversations }

  def within_service_window?
    last_inbound_at.present? && last_inbound_at > SERVICE_WINDOW.ago
  end

  def take_over!(user)
    update!(status: :human_active, assigned_user: user)
  end

  def hand_back_to_ai!
    update!(status: :ai_active)
  end

  def close!
    update!(status: :closed)
  end

  def reopen!
    update!(status: :ai_active)
  end

  def last_message
    messages.last
  end
end
