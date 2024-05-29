class EnsureCourseIdentifiersAreUnique < ActiveRecord::Migration[7.1]
  def change
    add_index :courses, :identifier, unique: true
  end
end
