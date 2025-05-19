class DropSettings < ActiveRecord::Migration[7.1]
  def change
    drop_table :settings do |t|
      t.date :course_start_date
      t.timestamps
    end
  end
end
