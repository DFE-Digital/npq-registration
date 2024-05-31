class CreateCourseGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :course_groups do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :course_groups, :name, unique: true
  end
end
