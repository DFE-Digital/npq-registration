class AddPreviousNamesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :previous_names, :citext, array: true, null: false, default: []
  end
end
