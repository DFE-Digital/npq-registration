class AddArchivedEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :archived_email, :string
  end
end
