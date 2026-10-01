class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user, optional: true

  enum :direction, { inbound: 0, outbound: 1 }
  enum :sender_type, { customer: 0, ai: 1, staff: 2, system: 3 }, prefix: :sent_by
  enum :delivery_status, { pending: 0, sent: 1, delivered: 2, read: 3, failed: 4 }, default: :pending

  validates :body, presence: true
  validates :wa_message_id, uniqueness: true, allow_nil: true
  validates :user, presence: true, if: :sent_by_staff?

  after_create_commit :touch_conversation
  after_create_commit -> { broadcast_append_later_to conversation, target: "messages" }

  private
    def touch_conversation
      attrs = { last_message_at: created_at }
      attrs[:last_inbound_at] = created_at if inbound?
      conversation.update!(attrs)
    end
end
