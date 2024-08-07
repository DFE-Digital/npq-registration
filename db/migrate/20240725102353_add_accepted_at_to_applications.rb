class AddAcceptedAtToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :accepted_at, :datetime
  end
end
