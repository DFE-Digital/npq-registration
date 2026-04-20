FactoryBot.define do
  factory :course_cohort do
    course { create(:course, :senior_leadership) }
    cohort { create(:cohort, :current) }
  end
end
