FactoryBot.define do
  factory :course_group do
    sequence(:name) { |n| "Course Group #{n}" }

    initialize_with do
      CourseGroup.find_by(name:) || new(**attributes)
    end
  end
end
