require "securerandom"

FactoryBot.define do
  factory :application do
    application_for_school

    user
    course
    lead_provider { LeadProvider.all.sample }
    headteacher_status { "no" }
    ecf_id { SecureRandom.uuid }
    cohort
    teacher_catchment { "england" }
    teacher_catchment_country { "United Kingdom of Great Britain and Northern Ireland" }
    teacher_catchment_iso_country_code { "GBR" }
    itt_provider
    funding_choice { Application.funding_choices.keys.sample }
    lead_mentor { true }

    trait :application_for_school do
      school { build(:school) }
      private_childcare_provider_id { nil }
      DEPRECATED_private_childcare_provider_urn { nil }

      works_in_school { true }
      works_in_childcare { false }
      kind_of_nursery { nil }
    end

    trait :application_for_private_childcare_provider do
      school_urn { nil }
      private_childcare_provider { build(:private_childcare_provider) }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }
    end

    trait :application_for_public_childcare_provider do
      school { build(:school) }
      private_childcare_provider_id { nil }
      DEPRECATED_private_childcare_provider_urn { nil }

      works_in_school { false }
      works_in_childcare { true }
      kind_of_nursery { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }
    end

    trait :accepted do
      lead_provider_approval_status { :accepted }
    end

    trait :pending do
      lead_provider_approval_status { :pending }
    end

    trait :eligible_for_funding do
      eligible_for_funding { true }
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

    trait :with_random_lead_provider_approval_status do
      lead_provider_approval_status { %w[accepted rejected].sample }
    end

    trait :with_random_participant_outcome_state do
      participant_outcome_state { %w[passed failed].sample }
    end

    trait :with_random_user do
      user { FactoryBot.build(:user, :with_random_name) }
    end

    trait :with_participant_id_change do
      after(:create) do |application|
        user = application.user

        FactoryBot.create(:participant_id_change, to_participant: user, user:)
      end
    end
  end
end
