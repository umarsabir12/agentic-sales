class AddHandoffToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :handoff_reason, :string
    add_column :conversations, :handed_off_at, :datetime
  end
end
