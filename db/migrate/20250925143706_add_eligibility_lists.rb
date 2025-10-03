class AddEligibilityLists < ActiveRecord::Migration[7.2]
  def change
    create_table :eligibility_lists do |t|
      t.string :type, null: false, index: true
      t.string :identifier, null: false, index: true
      t.string :identifier_type, null: false
      t.timestamps
    end

    add_index :eligibility_lists, %i[type identifier identifier_type], unique: true
  end
end
