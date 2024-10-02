# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_declaration, class: "Migration::Ecf::ParticipantDeclaration" do
    declaration_date { 1.hour.ago }
    state { Declaration.states.keys.sample }
    declaration_type { Declaration.declaration_types.keys.sample }
    type { "ParticipantDeclaration::NPQ" }
    course_identifier { "course-identifier" }
    user { create(:ecf_migration_user) }
    cohort { create(:ecf_migration_cohort) }
    cpd_lead_provider { create(:ecf_migration_npq_lead_provider).cpd_lead_provider }

    trait :ineligible do
      after(:build) do |participant_declaration|
        participant_declaration.declaration_states = build_list(:ecf_migration_declaration_state, 1, participant_declaration:)
      end
    end
  end
end
