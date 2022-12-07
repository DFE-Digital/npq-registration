class AddNurseryTypeToApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :applications, :nursery_type, :text
  end
end
