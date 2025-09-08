class AddIndexForWhodunnitToVersions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :versions, :whodunnit, algorithm: :concurrently
  end
end
