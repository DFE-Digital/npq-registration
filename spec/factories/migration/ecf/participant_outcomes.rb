# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_outcome, class: "Migration::Ecf::ParticipantOutcome::Npq" do
    association :participant_declaration, factory: :ecf_migration_participant_declaration
    completion_date { Date.yesterday }
    state { :passed }
    sent_to_qualified_teachers_api_at { 1.hour.ago }
    qualified_teachers_api_request_successful { true }
  end
end
