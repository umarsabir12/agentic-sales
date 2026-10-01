class Ticket < ApplicationRecord
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { open: 0, in_progress: 1, won: 2, lost: 3 }, default: :open
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, default: :medium, prefix: true
  enum :source, { ai: 0, manual: 1 }, default: :ai, prefix: true

  validates :title, presence: true

  scope :active, -> { where(status: %i[open in_progress]) }

  before_save :set_closed_at, if: :will_save_change_to_status?

  def closed?
    won? || lost?
  end

  private
    def set_closed_at
      self.closed_at = closed? ? (closed_at || Time.current) : nil
    end
end
