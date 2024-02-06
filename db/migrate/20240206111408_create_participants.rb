class CreateParticipants < ActiveRecord::Migration[7.1]
  def change
    create_enum :trn_lookup_states, %w[found failed]

    create_table :participants do |t|
      # personal stuff
      t.string "email", null: false
      t.text "full_name"
      t.date "date_of_birth"

      # ecf sync stuff
      t.text "ecf_id"
      t.boolean "get_an_identity_id_synced_to_ecf", default: false

      # trn stuff
      t.text "trn"
      t.boolean "trn_verified", default: false, null: false
      t.enum "trn_lookup_state", enum_type: :trn_lookup_states # renamed from trn_lookup_status

      # other
      t.string "provider"
      t.jsonb "raw_tra_provider_data" # ideally let's not store this raw in the database...
      t.boolean "notify_user_for_future_reg", default: false
      t.timestamps
    end
  end
end
