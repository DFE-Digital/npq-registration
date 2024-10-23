class AddUniqueConstraintToEcfIdInCourses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :courses, :ecf_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :courses, :ecf_id
  end
end
