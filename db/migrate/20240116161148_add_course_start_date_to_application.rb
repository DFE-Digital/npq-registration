class AddCourseStartDateToApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :course_start_date, :string
  end
end
