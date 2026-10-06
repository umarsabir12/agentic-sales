class AddTemplateToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :template_name, :string
    add_column :messages, :template_language, :string
    add_column :messages, :template_params, :jsonb, null: false, default: []
  end
end
