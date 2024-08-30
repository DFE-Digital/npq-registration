# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_participant_id_change, class: "Migration::Ecf::ParticipantIdChange" do
    user { create(:ecf_migration_user) }
    from_participant { create(:ecf_migration_user) }
    to_participant { create(:ecf_migration_user) }
  end
end
