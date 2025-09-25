class AddEligibilityLists < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :eligibility_list_entries do |t|
      t.string :type, null: false, index: true
      t.string :identifier, null: false, index: true
      t.string :identifier_type, null: false
      t.timestamps
    end

    add_index :eligibility_list_entries, %i[type identifier identifier_type], unique: true, algorithm: :concurrently
  end
end
