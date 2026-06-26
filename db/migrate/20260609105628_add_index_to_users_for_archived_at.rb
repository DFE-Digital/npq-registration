class AddIndexToUsersForArchivedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :users, :archived_at, algorithm: :concurrently
  end
end
