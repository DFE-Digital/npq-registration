class AddTrainingStatusToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :training_status, :enum, enum_type: "application_statuses", default: "active", null: false
  end
end
