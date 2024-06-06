class AddCourseGroupToCourses < ActiveRecord::Migration[7.1]
  def change
    add_reference :courses, :course_group, foreign_key: true
  end
end
