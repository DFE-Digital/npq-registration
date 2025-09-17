class ChangeEmploymentTypeToEnumInApplications < ActiveRecord::Migration[7.2]
  def up
    create_enum :employment_types, %w[
      hospital_school
      lead_mentor_for_accredited_itt_provider
      local_authority_supply_teacher
      local_authority_virtual_school
      young_offender_institution
      other
    ]

    safety_assured do
      change_column :applications, :employment_type, "employment_types USING employment_type::employment_types"
    end
  end

  def down
    change_column :applications, :employment_type, :string
    drop_enum :employment_types
  end
end
