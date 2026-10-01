class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :direction, null: false
      t.integer :sender_type, null: false
      t.references :user, foreign_key: true
      t.text :body
      t.string :wa_message_id
      t.integer :delivery_status, null: false, default: 0
      t.datetime :sent_at

      t.timestamps
    end
    add_index :messages, :wa_message_id, unique: true
  end
end
