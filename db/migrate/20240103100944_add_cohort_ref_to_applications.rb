class AddCohortRefToApplications < ActiveRecord::Migration[7.0]
  def change
    add_reference :applications, :cohort, null: true, foreign_key: true
  end
end
