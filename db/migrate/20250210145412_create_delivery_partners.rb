class CreateDeliveryPartners < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_partners do |t|
      t.uuid :ecf_id, null: false, default: "gen_random_uuid()"
      t.string :name, null: false

      t.timestamps
    end
    add_index :delivery_partners, :ecf_id, unique: true
    add_index :delivery_partners, :name, unique: true
  end
end
