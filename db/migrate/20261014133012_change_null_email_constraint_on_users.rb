class ChangeNullEmailConstraintOnUsers < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint(
      :users,
      name: "users_email_null_only_when_archived",
    )

    # clear archived_at for users that have applications and have a reused email
    safety_assured do
      execute <<~SQL
        UPDATE users
        SET archived_at = NULL
        WHERE id IN (
          SELECT DISTINCT user_id
          FROM applications
        )
        AND email IS NULL
        AND email_reused_at IS NOT NULL
      SQL
    end

    add_check_constraint(
      :users,
      "email IS NOT NULL OR (archived_email IS NOT NULL AND email_reused_at IS NOT NULL)",
      name: "users_email_null_only_when_reused",
      validate: false,
    )
  end

  def down
    remove_check_constraint(
      :users,
      name: "users_email_null_only_when_reused",
    )

    safety_assured do
      execute <<~SQL
        UPDATE users
        SET archived_at = email_reused_at
        WHERE id IN (
          SELECT DISTINCT user_id
          FROM applications
        )
        AND email IS NULL
        AND email_reused_at IS NOT NULL
      SQL
    end

    add_check_constraint(
      :users,
      "email IS NOT NULL OR (archived_email IS NOT NULL AND archived_at IS NOT NULL)",
      name: "users_email_null_only_when_archived",
      validate: false,
    )
  end
end
