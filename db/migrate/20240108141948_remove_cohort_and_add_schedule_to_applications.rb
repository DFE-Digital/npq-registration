class RemoveCohortAndAddScheduleToApplications < ActiveRecord::Migration[7.1]
  def up
    remove_reference :applications, :cohort, foreign_key: true
    add_reference :applications, :schedule, null: true, foreign_key: true
  end

  def down
    remove_reference :applications, :schedule, foreign_key: true
    add_reference :applications, :cohort, null: true, foreign_key: true
  end
end

