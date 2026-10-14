class AddUsersEmailReusedAt < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_reused_at, :datetime
  end
end
