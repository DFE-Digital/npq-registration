class AddTrnPresentWhenVerifiedConstraintToUsers < ActiveRecord::Migration[8.0]
  def up
    # Clean rows that would fail the constraint before adding it.
    safety_assured do
      execute(<<~SQL)
        UPDATE users
        SET trn_verified = false
        WHERE trn_verified = true
          AND (trn IS NULL OR trn = '')
      SQL
    end

    add_check_constraint(
      :users,
      "NOT trn_verified OR (trn IS NOT NULL AND trn <> '')",
      name: "users_trn_present_when_verified",
      validate: false,
    )
  end

  def down
    remove_check_constraint :users, name: "users_trn_present_when_verified"
  end
end
