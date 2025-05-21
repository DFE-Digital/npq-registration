class AddReviewStatusToApplications < ActiveRecord::Migration[7.1]
  def up
    create_enum :review_statuses,
                %w[needs_review awaiting_information reregister decision_made]

    add_column :applications, :review_status, :enum, enum_type: "review_statuses",
                                                     null: true
  end

  def down
    remove_column :applications, :review_status
    drop_enum :review_statuses
  end
end
