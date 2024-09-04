# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_profile_state, class: "Migration::Ecf::ParticipantProfileState" do
    state { :active }
    reason { "reason" }
    participant_profile { create(:ecf_migration_npq_participant_profile) }
    cpd_lead_provider { create(:ecf_migration_npq_lead_provider).cpd_lead_provider }
  end
end
