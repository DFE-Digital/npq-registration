class AllowNullEmailOnUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :email, true
    change_column_default :users, :email, from: "", to: nil

    add_check_constraint(
      :users,
      "email IS NOT NULL OR (archived_email IS NOT NULL AND archived_at IS NOT NULL)",
      name: "users_email_null_only_when_archived",
      validate: false,
    )
  end
end
