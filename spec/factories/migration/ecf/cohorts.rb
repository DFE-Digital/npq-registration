# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_cohort, class: "Migration::Ecf::Cohort" do
    start_year { Date.current.year - (Date.current.month < 9 ? 1 : 0) }
    registration_start_date { Date.new(start_year.to_i, 6, 5) }
    academic_year_start_date { Date.new(start_year.to_i, 9, 1) }
    automatic_assignment_period_end_date { Date.new(start_year.to_i + 1, 3, 31) }

    initialize_with do
      Migration::Ecf::Cohort.find_by(start_year:) || new(**attributes)
    end

    trait :with_sequential_start_year do
      sequence(:start_year) { |n| 2021 + (n % 9) }
    end

    trait :with_npq_registration_start_date do
      npq_registration_start_date { Date.new(start_year.to_i, 7, 6) }
    end
  end
end
