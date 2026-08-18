class ConvertClosedRegistrationUsersToCitext < ActiveRecord::Migration[8.1]
  def up
    change_column :closed_registration_users, :email, :citext
  end

  def down
    change_column :closed_registration_users, :email, :string
  end
end
