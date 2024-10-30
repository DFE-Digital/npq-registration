# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_declaration, class: "Migration::Ecf::ParticipantDeclaration" do
    declaration_date { 1.hour.ago }
    state { Declaration.states.keys.sample }
    declaration_type { Declaration.declaration_types.keys.sample }
    type { "ParticipantDeclaration::NPQ" }
    participant_profile { create(:ecf_migration_npq_application, :accepted).profile }
    course_identifier { participant_profile.npq_application.npq_course.identifier }
    user { participant_profile.user }
    cohort { participant_profile.npq_application.cohort }
    cpd_lead_provider { participant_profile.npq_application.npq_lead_provider.cpd_lead_provider }

    trait :ineligible do
      after(:build) do |participant_declaration|
        participant_declaration.declaration_states = build_list(:ecf_migration_declaration_state, 1, participant_declaration:)
      end
    end
  end
end
