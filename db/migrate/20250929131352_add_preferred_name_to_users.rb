class AddPreferredNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :preferred_name, :string
  end
end
