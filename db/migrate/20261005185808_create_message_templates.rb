class CreateMessageTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :message_templates do |t|
      t.string :name, null: false
      t.string :language, null: false, default: "en_US"
      t.string :category, null: false
      t.string :status, null: false, default: "DRAFT"
      t.string :wa_template_id
      t.string :header_format
      t.string :header_text
      t.text :body, null: false
      t.jsonb :body_examples, null: false, default: []
      t.string :footer
      t.jsonb :buttons, null: false, default: []
      t.string :rejected_reason
      t.datetime :synced_at

      t.timestamps
    end
    add_index :message_templates, %i[ name language ], unique: true
    add_index :message_templates, :wa_template_id, unique: true
  end
end
