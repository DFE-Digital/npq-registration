class CreateAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :admins do |t|
      t.string "email", null: false, limit: 64
      t.string "full_name", null: false, limit: 64
      t.boolean "super_admin", default: false, null: false

      t.text "otp_hash"
      t.datetime "otp_expires_at", precision: nil

      t.timestamps
    end
  end
end
