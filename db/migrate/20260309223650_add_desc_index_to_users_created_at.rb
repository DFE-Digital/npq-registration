class AddDescIndexToUsersCreatedAt < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :created_at, order: { created_at: :desc }, name: "index_users_on_created_at_desc", algorithm: :concurrently
    remove_index :users, column: :created_at, name: "index_users_on_created_at", algorithm: :concurrently
  end
end
