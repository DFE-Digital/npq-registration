class AddEligibilityLists < ActiveRecord::Migration[7.2]
  def change
    # create_enum :eligibility_list_types, %w[
      # pp50_school
      # pp50_further_education
      # childminder
      # disadvantaged_early_years_school
      # local_authority_nursery
      # rise_school
    # ]

    create_table :eligibility_lists do |t|
      # t.enum :type, enum_type: :eligibility_list_types, null: false, index: true
      t.string :type, null: false, index: true
      t.string :identifier, null: false, index: true
      t.string :identifier_type, null: false
      t.timestamps
    end

    add_index :eligibility_lists, %i[type identifier identifier_type], unique: true
  end
end
