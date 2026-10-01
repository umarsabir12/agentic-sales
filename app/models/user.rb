class User < ApplicationRecord
  # Team accounts are created by admins, so public sign-up (:registerable) is disabled.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :assigned_conversations, class_name: "Conversation", foreign_key: :assigned_user_id, dependent: :nullify
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, dependent: :nullify
  has_many :messages, dependent: :nullify

  enum :role, { agent: 0, admin: 1 }, default: :agent

  validates :name, presence: true

  def initials
    name.split.map(&:first).first(2).join.upcase
  end
end
