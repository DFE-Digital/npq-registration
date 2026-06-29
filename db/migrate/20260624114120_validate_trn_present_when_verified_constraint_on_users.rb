class ValidateTrnPresentWhenVerifiedConstraintOnUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    validate_check_constraint :users, name: "users_trn_present_when_verified"
  end
end
