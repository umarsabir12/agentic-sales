# Singleton row holding how the AI sales agent behaves. Edited by admins in the portal.
class AgentSetting < ApplicationRecord
  EFFORTS = %w[ low medium high ].freeze

  validates :effort, inclusion: { in: EFFORTS }
  validates :reply_delay_seconds, numericality: { only_integer: true, in: 0..60 }

  def self.current
    first_or_create!
  end
end
