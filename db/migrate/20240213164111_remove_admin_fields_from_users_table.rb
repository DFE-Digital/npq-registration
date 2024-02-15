class RemoveAdminFieldsFromUsersTable < ActiveRecord::Migration[7.1]
  def up
    Admins::ConvertAdminUserToAdmin.new.convert_all_admin_users_to_admins!

    remove_column :users, :otp_hash
    remove_column :users, :otp_expires_at
    remove_column :users, :admin
    remove_column :users, :super_admin
  end
end
