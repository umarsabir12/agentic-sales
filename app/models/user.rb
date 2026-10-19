class User < ApplicationRecord
  # People can sign up, but an admin must approve them before they can sign in,
  # because every user can read customer conversations.
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :assigned_conversations, class_name: "Conversation", foreign_key: :assigned_user_id, dependent: :nullify
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, dependent: :nullify
  has_many :messages, dependent: :nullify

  enum :role, { agent: 0, admin: 1 }, default: :agent

  validates :name, presence: true

  scope :pending, -> { where(approved_at: nil) }

  def initials
    name.split.map(&:first).first(2).join.upcase
  end

  def approved?
    approved_at.present?
  end

  def approve!
    update!(approved_at: Time.current)
  end

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    approved? ? super : :not_approved
  end
end
