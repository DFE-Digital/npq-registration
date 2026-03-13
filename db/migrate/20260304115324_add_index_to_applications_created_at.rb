class AddIndexToApplicationsCreatedAt < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :applications, :created_at, algorithm: :concurrently
  end
end
