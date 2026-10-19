class Contact < ApplicationRecord
  has_many :conversations, dependent: :destroy
  has_many :tickets, dependent: :destroy

  # Store phone numbers in E.164 digits-only form (e.g. "923001234567"), matching WhatsApp's wa_id.
  # A leading "00" is the international dialling prefix, so it is dropped.
  normalizes :phone, with: ->(p) { p.to_s.gsub(/\D/, "").delete_prefix("00") }

  validates :phone, presence: true, uniqueness: true
  validates :phone, format: { with: /\A[1-9]\d{7,14}\z/, message: "must start with the country code, e.g. +92 300 1234567" }, on: :create

  def display_name
    name.presence || profile_name.presence || "+#{phone}"
  end

  def avatar_letter
    (name.presence || profile_name.presence)&.first&.upcase || "#"
  end

  def current_conversation
    conversations.where.not(status: :closed).order(created_at: :desc).first
  end
end
