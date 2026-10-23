class AddCourseToRegistrationInterests < ActiveRecord::Migration[8.1]
  def change
    create_enum :registration_interest_course, %w[npq-senco other]

    add_column :registration_interests,
               :course,
               :enum,
               enum_type: :registration_interest_course,
               null: false,
               default: "other"
  end
end
