require "securerandom"

FactoryBot.define do
  factory :application do
    with_school

    user
    course
    lead_provider { LeadProvider.all.sample }
    headteacher_status { "no" }
    lead_provider_approval_status { :pending }
    ecf_id { SecureRandom.uuid }
    cohort
    teacher_catchment { "england" }
    teacher_catchment_country { "United Kingdom of Great Britain and Northern Ireland" }
    teacher_catchment_iso_country_code { "GBR" }
    itt_provider
    funding_choice { Application.funding_choices.keys.sample }
    lead_mentor { Faker::Boolean.boolean }

    trait :with_school do
      school
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
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }
    end

    trait :with_public_childcare_provider do
      school
      private_childcare_provider_id { nil }
      DEPRECATED_private_childcare_provider_urn { nil }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }
    end

    trait :with_declaration do
      accepted

      after(:create) do |application|
        create(:declaration, application:)
      end
    end

    trait :accepted do
      lead_provider_approval_status { :accepted }
      schedule { Schedule.where(cohort:, course_group: course.course_group).sample || create(:schedule, course_group: course.course_group, cohort:) }
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
      funded_place { true }

      after(:create) do |application|
        application.cohort.update!(funding_cap: true)
      end
    end

    trait :previously_funded do
      after(:create) do |application|
        course = application.course.rebranded_alternative_courses.sample

        create(:application, :accepted, :eligible_for_funding, user: application.user, course:)
      end
    end

    trait :with_random_work_setting do
      work_setting { %w[a_school an_academy_trust a_16_to_19_educational_setting].sample }
    end

    trait :with_random_participant_outcome_state do
      participant_outcome_state { %w[passed failed].sample }
    end

    trait :with_random_user do
      user { build(:user, :with_random_name) }
    end

    trait :with_random_eligible_for_funding do
      eligible_for_funding { Faker::Boolean.boolean }
    end

    trait :with_participant_id_change do
      after(:create) do |application|
        user = application.user

        create(:participant_id_change, to_participant: user, user:)
      end
    end

    trait :withdrawn do
      after(:create) do |application|
        application.update!(training_status: ApplicationState.states[:withdrawn])

        create(:application_state,
               application:,
               lead_provider: application.lead_provider,
               state: ApplicationState.states[:withdrawn],
               reason: "other")
      end
    end

    trait :deferred do
      after(:create) do |application|
        application.update!(training_status: ApplicationState.states[:deferred])

        create(:application_state,
               application:,
               lead_provider: application.lead_provider,
               state: ApplicationState.states[:deferred],
               reason: "other")
      end
    end
  end
end
