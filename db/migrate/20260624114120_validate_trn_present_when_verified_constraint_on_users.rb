class ValidateTrnPresentWhenVerifiedConstraintOnUsers < ActiveRecord::Migration[8.0]
  def up
    # Clean rows that would fail the constraint before validating it.
    safety_assured do
      execute(<<~SQL)
        UPDATE users
        SET trn_verified = false
        WHERE trn_verified = true
          AND (trn IS NULL OR trn = '')
      SQL
    end

    validate_check_constraint :users, name: "users_trn_present_when_verified"
  end

  def down; end
end
