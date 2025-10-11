class IndexUsersOnTrn < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :users, :trn, algorithm: :concurrently
  end
end
