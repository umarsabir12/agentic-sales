class AddErrorToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :error_message, :string
  end
end
