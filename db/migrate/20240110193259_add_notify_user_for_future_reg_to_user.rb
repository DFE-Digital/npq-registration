class AddNotifyUserForFutureRegToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notify_user_for_future_reg, :boolean, default: false
  end
end
