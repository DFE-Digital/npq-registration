class AddReasonForRejectionToApplications < ActiveRecord::Migration[7.2]
  def change
    create_enum :reasons_for_rejection,
                %w[registration_expired rejected_by_provider application_accepted_by_other_provider]

    add_column :applications, :reason_for_rejection, :enum, enum_type: "reasons_for_rejection", null: true
  end
end
