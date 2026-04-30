FactoryBot.define do
  factory :course_cohort do
    course { create(:course, :senior_leadership) }
    cohort { create(:cohort, :current) }

    trait :with_provider do
      transient do
        lead_provider { create(:lead_provider) }
      end

      after(:create) do |course_cohort, evaluator|
        create(:course_cohort_provider, course_cohort:, lead_provider: evaluator.lead_provider)
      end
    end
  end
end
