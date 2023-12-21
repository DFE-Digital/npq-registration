class DropSchedules < ActiveRecord::Migration[7.0]
  def up
    drop_table :schedules
  end
end
