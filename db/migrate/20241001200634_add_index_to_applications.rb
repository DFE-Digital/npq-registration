class AddIndexToApplications < ActiveRecord::Migration[7.1]
  def change
    add_index :applications, :ecf_id
  end
end
