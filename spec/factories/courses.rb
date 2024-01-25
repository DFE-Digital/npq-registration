FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    sequence(:identifier) { |n| "npq-course-#{n}" }
  end
end
