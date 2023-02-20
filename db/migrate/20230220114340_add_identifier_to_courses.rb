class AddIdentifierToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :identifier, :string

    Services::Courses::DefinitionLoader.call
  end
end
