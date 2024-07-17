class AddReferredByReturnToTeachingAdviserToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :referred_by_return_to_teaching_adviser, :string
  end
end
