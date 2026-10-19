class AddCompanyAndApprovalToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :company, :string
    add_column :users, :approved_at, :datetime

    # Everyone who already has an account was added by an admin.
    reversible do |dir|
      dir.up { execute "UPDATE users SET approved_at = CURRENT_TIMESTAMP" }
    end
  end
end
