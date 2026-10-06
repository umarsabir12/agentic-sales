class AddComponentsToMessageTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :message_templates, :components, :jsonb, null: false, default: []
  end
end
