class AddFundedPlaceToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :funded_place, :boolean
  end
end
