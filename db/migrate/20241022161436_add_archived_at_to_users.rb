class AddArchivedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :archived_at, :datetime
  end
end
