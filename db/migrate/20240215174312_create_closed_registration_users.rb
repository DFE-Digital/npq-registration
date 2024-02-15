class CreateClosedRegistrationUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :closed_registration_users do |t|
      t.string :email

      t.timestamps
    end
  end
end
