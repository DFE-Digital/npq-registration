# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_participant_profile, class: "Migration::Ecf::ParticipantProfile" do
    transient do
      user { create(:ecf_migration_user) }
      cohort { create(:ecf_migration_cohort) }
      npq_course { create(:ecf_migration_npq_course) }
      participant_identity { user.participant_identities.first || create(:ecf_migration_participant_identity, user:) }
      npq_lead_provider { create(:ecf_migration_npq_lead_provider) }
      teacher_reference_number { user.teacher_profile&.trn || sprintf("%07i", Random.random_number(9_999_999)) }
      npq_application do
        create(:ecf_migration_npq_application, :accepted, npq_lead_provider:, npq_course:, cohort:, participant_identity:, teacher_reference_number:)
      end
    end

    type { "ParticipantProfile::NPQ" }
    schedule { create(:ecf_migration_schedule) }
    teacher_profile { user.teacher_profile || create(:ecf_migration_teacher_profile, user:) }

    initialize_with do
      npq_application.profile
    end
  end
end
