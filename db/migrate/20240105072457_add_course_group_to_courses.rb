class AddCourseGroupToCourses < ActiveRecord::Migration[7.0]
  def change
    add_reference :courses, :course_group, null: true, foreign_key: true
  end
end
