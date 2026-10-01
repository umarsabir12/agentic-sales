class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :contact, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :last_message_at
      t.datetime :last_inbound_at
      t.references :assigned_user, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :conversations, :last_message_at
  end
end
