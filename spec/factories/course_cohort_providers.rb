FactoryBot.define do
  factory :course_cohort_provider do
    course_cohort { create(:course_cohort) }
    lead_provider { create(:lead_provider) }
  end
end
