class CreateDeliveryPartners < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_partners do |t|
      t.uuid :ecf_id, null: false, default: "gen_random_uuid()"
      t.string :name, null: false

      t.timestamps

      t.index :ecf_id, unique: true
      t.index :name, unique: true
    end

    create_table :delivery_partnerships do |t|
      t.references :delivery_partner, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true

      t.timestamps

      t.index %i[delivery_partner_id lead_provider_id cohort_id], unique: true
    end
  end
end
