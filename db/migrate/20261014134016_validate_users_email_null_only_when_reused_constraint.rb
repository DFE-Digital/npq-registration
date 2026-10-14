class ValidateUsersEmailNullOnlyWhenReusedConstraint < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :users, name: "users_email_null_only_when_reused"
  end
end
