class ReplaceUserEmailIndexWithUniqueIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, unique: false, algorithm: :concurrently
  end
end
