FactoryBot.define do
  factory :course_group do
    sequence(:name) { |n| "Course Group #{n}" }
  end
end
