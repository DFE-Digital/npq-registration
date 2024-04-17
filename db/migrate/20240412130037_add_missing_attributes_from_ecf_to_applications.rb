class AddMissingAttributesFromEcfToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :teacher_catchment_iso_country_code, :string, limit: 3
    add_column :applications, :targeted_support_funding_eligibility, :boolean, default: false
    add_column :applications, :notes, :string

    add_reference :applications, :cohort, foreign_key: true
  end
end
