class AddArchivedAtToAdmins < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :admins, :archived_at, :datetime
    add_index :admins, :archived_at, algorithm: :concurrently
  end
end
