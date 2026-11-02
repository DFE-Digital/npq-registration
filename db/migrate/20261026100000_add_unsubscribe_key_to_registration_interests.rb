class AddUnsubscribeKeyToRegistrationInterests < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # registration_interests is a small table, so rewriting it to fill the default is fine
    safety_assured do
      add_column :registration_interests, :unsubscribe_key, :uuid, default: -> { "gen_random_uuid()" }, null: false
    end

    add_index :registration_interests, :unsubscribe_key, unique: true, algorithm: :concurrently
  end
end
