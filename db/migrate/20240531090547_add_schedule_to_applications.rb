class AddScheduleToApplications < ActiveRecord::Migration[7.1]
  def change
    add_reference :applications, :schedule, foreign_key: true
  end
end
