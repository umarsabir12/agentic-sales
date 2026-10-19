class CreateAgentSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_settings do |t|
      t.boolean :enabled, null: false, default: true
      t.string :business_name, null: false, default: ""
      t.text :instructions, null: false, default: ""
      t.string :effort, null: false, default: "medium"
      t.integer :reply_delay_seconds, null: false, default: 5

      t.timestamps
    end
  end
end
