class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :summary
      t.string :product_interest
      t.string :budget
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.integer :source, null: false, default: 0
      t.datetime :closed_at

      t.timestamps
    end
  end
end
