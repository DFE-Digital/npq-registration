class AddTrnPresentWhenVerifiedConstraintToUsers < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint(
      :users,
      "NOT trn_verified OR (trn IS NOT NULL AND trn <> '')",
      name: "users_trn_present_when_verified",
      validate: false,
    )
  end
end
