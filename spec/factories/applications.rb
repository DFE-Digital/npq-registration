require "securerandom"

FactoryBot.define do
  factory :application do
    with_school

    user
    course { create(Course::IDENTIFIERS.first.to_sym) }
    lead_provider { LeadProvider.first }
    headteacher_status { "no" }
    lead_provider_approval_status { :pending }
    ecf_id { SecureRandom.uuid }
    cohort { create(:cohort, :current) }
    teacher_catchment { "england" }
    teacher_catchment_country { "United Kingdom of Great Britain and Northern Ireland" }
    teacher_catchment_iso_country_code { "GBR" }
    itt_provider
    funding_choice { Application.funding_choices.keys.first }
    lead_mentor { false }
    ukprn { rand(10_000_000..99_999_999).to_s }

    trait :with_school do
      school
      ukprn { school.ukprn }
      private_childcare_provider_id { nil }
      DEPRECATED_private_childcare_provider_urn { nil }

      works_in_school { true }
      works_in_childcare { false }
      kind_of_nursery { nil }
    end

    trait :with_private_childcare_provider do
      private_childcare_provider

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.first }
    end

    trait :with_public_childcare_provider do
      school
      private_childcare_provider_id { nil }
      DEPRECATED_private_childcare_provider_urn { nil }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.first }
    end

    trait :with_declaration do
      accepted

      after(:create) do |application|
        create(:declaration, application:)
      end
    end

    trait :accepted do
      lead_provider_approval_status { :accepted }
      schedule { Schedule.find_by(cohort:, course_group: course.course_group) || create(:schedule, course_group: course.course_group, cohort:) }
      funded_place { cohort.funding_cap ? !!eligible_for_funding : nil }
      accepted_at { Time.zone.now }
      training_status { :active }
    end

    trait :rejected do
      lead_provider_approval_status { :rejected }
    end

    trait :pending do
      lead_provider_approval_status { :pending }
    end

    trait :eligible_for_funding do
      eligible_for_funding { true }
    end

    trait :eligible_for_funded_place do
      accepted
      eligible_for_funding

      after(:create) do |application|
        application.cohort.update!(funding_cap: true)
      end
    end

    trait :previously_funded do
      after(:create) do |application|
        course = application.course.rebranded_alternative_courses.first

        create(:application, :accepted, :eligible_for_funding, user: application.user, course:)
      end
    end

    trait :with_random_work_setting do
      work_setting { "a_school" }
    end

    trait :with_random_participant_outcome_state do
      participant_outcome_state { "passed" }
    end

    trait :with_random_user do
      user { build(:user, :with_random_name) }
    end

    # DO NOT USE: Only for seeds, do not use in specs - it will lead to flaky specs
    trait :with_random_eligible_for_funding_seeds_only do
      eligible_for_funding { Faker::Boolean.boolean }
    end

    trait :with_participant_id_change do
      after(:create) do |application|
        user = application.user

        create(:participant_id_change, to_participant_id: user.ecf_id, user:)
      end
    end

    trait :withdrawn do
      lead_provider_approval_status { :accepted }

      after(:create) do |application|
        application.update!(training_status: ApplicationState.states[:withdrawn])

        create(:application_state,
               :withdrawn,
               application:,
               lead_provider: application.lead_provider)
      end
    end

    trait :deferred do
      lead_provider_approval_status { :accepted }

      after(:create) do |application|
        application.update!(training_status: ApplicationState.states[:deferred])

        create(:application_state,
               :deferred,
               application:,
               lead_provider: application.lead_provider)
      end
    end

    trait :lead_mentor do
      lead_mentor { true }
    end

    trait :manual_review do
      review_status { "Needs review" }
    end
  end
end
