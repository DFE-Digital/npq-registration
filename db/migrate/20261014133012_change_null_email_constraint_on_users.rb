class ChangeNullEmailConstraintOnUsers < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint(
      :users,
      "email IS NOT NULL OR (archived_email IS NOT NULL AND archived_at IS NOT NULL)",
      name: "users_email_null_only_when_archived",
    )

    add_check_constraint(
      :users,
      "email IS NOT NULL OR (archived_email IS NOT NULL AND email_reused_at IS NOT NULL)",
      name: "users_email_null_only_when_reused",
      validate: false,
    )
  end
end
