class AddValueToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :value, :decimal, precision: 14, scale: 2
  end
end
