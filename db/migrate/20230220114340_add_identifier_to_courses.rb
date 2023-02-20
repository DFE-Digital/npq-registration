class AddIdentifierToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :identifier, :string

    Course::COURSE_ECF_ID_TO_IDENTIFIER_MAPPING.each do |ecf_id, identifier|
      Course.find_by!(ecf_id:).update(identifier:)
    end
  end
end
