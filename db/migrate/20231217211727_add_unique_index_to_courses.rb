class AddUniqueIndexToCourses < ActiveRecord::Migration[7.0]
  def change
    add_index :courses, :identifier, unique: true
  end
end
