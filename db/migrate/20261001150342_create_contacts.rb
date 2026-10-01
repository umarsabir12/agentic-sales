class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.string :phone, null: false
      t.string :name
      t.string :profile_name
      t.text :notes

      t.timestamps
    end
    add_index :contacts, :phone, unique: true
  end
end
