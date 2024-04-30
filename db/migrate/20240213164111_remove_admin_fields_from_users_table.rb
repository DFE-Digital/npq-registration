class RemoveAdminFieldsFromUsersTable < ActiveRecord::Migration[7.1]
  def up
    remove_column :users, :otp_hash
    remove_column :users, :otp_expires_at
    remove_column :users, :admin
    remove_column :users, :super_admin
  end
end
