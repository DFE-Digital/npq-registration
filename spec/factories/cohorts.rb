FactoryBot.define do
  factory :cohort do
    sequence(:start_year, 0) { |n| 2021 + n % 9 }
    registration_start_date { Date.new(start_year, 4, 3) }
    funding { "capped" }
    suffix { "a" }

    description do
      suffix_label = suffix == "a" ? nil : ": suffix #{suffix}"
      "#{start_year} to #{start_year.next}#{suffix_label}"
    end

    initialize_with do
      Cohort.find_or_create_by(start_year:, suffix:)
    end

    trait :current do
      start_year { Date.current.month < 9 ? Date.current.year.pred : Date.current.year }
    end

    trait :next do
      start_year { Date.current.month < 9 ? Date.current.year : Date.current.year.succ }
    end

    trait :previous do
      start_year { Date.current.month < 9 ? (Date.current.year - 2) : Date.current.year.pred }
    end

    trait :with_funding_cap do
      funding { "capped" }
    end

    trait :without_funding_cap do
      funding { "full" }
    end

    trait :unfunded do
      funding { "zero" }
    end

    trait :has_targeted_delivery_funding do
      start_year { 2022 }
    end

    trait :with_all_courses_for_provider do
      transient do
        lead_provider { create(:lead_provider) }
      end

      after(:create) do |cohort, evaluator|
        Course::IDENTIFIERS.each do |course_identifier|
          course = Course.find_by(identifier: course_identifier)
          course_cohort = create(:course_cohort, course:, cohort:)
          create(:course_cohort_provider, course_cohort:, lead_provider: evaluator.lead_provider)
        end
      end
    end
  end
end
