class AddUniqueIndexToAdmins < ActiveRecord::Migration[7.1]
  def change
    add_index :admins, :email, unique: true
  end
end
