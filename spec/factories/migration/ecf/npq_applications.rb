# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_application, class: "Migration::Ecf::NpqApplication" do
    cohort_id { create(:ecf_migration_cohort).id }
    npq_course_id { create(:ecf_migration_npq_course).id }
    npq_lead_provider_id { create(:ecf_migration_npq_lead_provider).id }
    participant_identity_id { create(:ecf_migration_participant_identity).id }
    works_in_school { true }
    school_urn { rand(100_000..999_999).to_s }
    school_ukprn { rand(10_000_000..99_999_999).to_s }
    date_of_birth { rand(25..50).years.ago + rand(0..365).days }
    teacher_reference_number { rand(1_000_000..9_999_999).to_s }
    teacher_reference_number_verified { true }
    nino { SecureRandom.hex }
    active_alert { false }
    eligible_for_funding { false }
    funding_eligiblity_status_code { :ineligible_establishment_type }
    targeted_delivery_funding_eligibility { false }
    teacher_catchment { "england" }
    teacher_catchment_country { nil }
    itt_provider { "University of Southampton" }
    lead_mentor { true }

    trait :accepted do
      lead_provider_approval_status { "accepted" }

      after(:create) do |npq_application|
        Migration::Ecf::ParticipantProfile.create!(
          id: npq_application.id,
          teacher_profile: npq_application.user.teacher_profile,
          user: npq_application.user,
          type: "ParticipantProfile::NPQ",
          schedule: create(:ecf_migration_schedule, cohort: npq_application.cohort, schedule_identifier: npq_application.npq_course.identifier),
        )
      end
    end
  end
end
