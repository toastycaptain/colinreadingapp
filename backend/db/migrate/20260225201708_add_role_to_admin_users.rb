class AddRoleToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :role, :integer, null: false, default: 0
    add_index :admin_users, :role
  end
end
