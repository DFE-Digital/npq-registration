class ValidateAllowNullEmailOnUsers < ActiveRecord::Migration[7.1]
  def change
    validate_check_constraint :users, name: "users_email_null_only_when_archived"
  end
end
