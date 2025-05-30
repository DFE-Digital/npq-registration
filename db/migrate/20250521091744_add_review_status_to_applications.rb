class AddReviewStatusToApplications < ActiveRecord::Migration[7.1]
  def up
    create_enum :review_statuses,
                %w[needs_review awaiting_information reregister decision_made]

    add_column :applications, :review_status, :enum, enum_type: "review_statuses",
                                                     null: true

    safety_assured do
      execute <<~SQL
        UPDATE applications
        SET review_status='decision_made'
        WHERE
          referred_by_return_to_teaching_adviser='yes'
          OR
          "employment_type" IN (
            'hospital_school', 'lead_mentor_for_accredited_itt_provider',
            'local_authority_supply_teacher', 'local_authority_virtual_school',
            'young_offender_institution', 'other'
          )
      SQL
    end
  end

  def down
    remove_column :applications, :review_status
    drop_enum :review_statuses
  end
end
