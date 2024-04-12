# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_identity, class: "Migration::Ecf::ParticipantIdentity" do
    user { create(:ecf_migration_user) }
    email { user.email }
    external_identifier { user.id }
    origin { "npq" }
  end
end
