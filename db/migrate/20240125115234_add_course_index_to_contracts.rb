class AddCourseIndexToContracts < ActiveRecord::Migration[7.1]
  def change
    add_index :contracts, %i[course_id statement_id], unique: true
  end
end
