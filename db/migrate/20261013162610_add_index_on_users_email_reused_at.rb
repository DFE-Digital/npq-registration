class AddIndexOnUsersEmailReusedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :users, :email_reused_at, algorithm: :concurrently
  end
end
