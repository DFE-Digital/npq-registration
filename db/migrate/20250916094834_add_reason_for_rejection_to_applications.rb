class AddReasonForRejectionToApplications < ActiveRecord::Migration[7.2]
  def change
    create_enum :reasons_for_rejection,
                %w[registration_expired rejected_by_provider other_application_in_this_cohort_accepted]

    add_column :applications, :reason_for_rejection, :enum, enum_type: "reasons_for_rejection", null: true
  end
end
