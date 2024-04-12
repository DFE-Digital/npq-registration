class AddUniqueIndexToUsersEcfId < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :ecf_id
    add_index :users, :ecf_id, unique: true
  end
end
