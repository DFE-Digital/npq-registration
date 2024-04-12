class AddMissingAttributesFromEcfToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :teacher_catchment_iso_country_code, :string, limit: 3
    add_column :applications, :targeted_support_funding_eligibility, :boolean, default: false
    add_column :applications, :notes, :string
    add_column :applications, :eligible_for_funding_updated_at, :datetime

    add_column :applications, :eligible_for_funding_updated_by_id, :text
    add_foreign_key :applications, :users, column: :eligible_for_funding_updated_by_id, primary_key: :ecf_id

    add_reference :applications, :cohort, foreign_key: true
  end
end
