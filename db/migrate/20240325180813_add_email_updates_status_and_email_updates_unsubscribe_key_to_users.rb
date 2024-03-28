class AddEmailUpdatesStatusAndEmailUpdatesUnsubscribeKeyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_updates_status, :integer, default: 0
    add_column :users, :email_updates_unsubscribe_key, :string
  end
end
