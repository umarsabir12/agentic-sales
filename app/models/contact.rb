class Contact < ApplicationRecord
  has_many :conversations, dependent: :destroy
  has_many :tickets, dependent: :destroy

  # Store phone numbers in E.164 digits-only form (e.g. "923001234567"), matching WhatsApp's wa_id.
  normalizes :phone, with: ->(p) { p.to_s.gsub(/\D/, "") }

  validates :phone, presence: true, uniqueness: true

  def display_name
    name.presence || profile_name.presence || "+#{phone}"
  end

  def current_conversation
    conversations.where.not(status: :closed).order(created_at: :desc).first
  end
end
