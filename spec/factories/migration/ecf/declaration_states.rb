# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_declaration_state, class: "Migration::Ecf::DeclarationState" do
    participant_declaration { create(:ecf_migration_participant_declaration) }

    trait :ineligible do
      state { :ineligible }
      state_reason { Declaration.state_reasons.keys.sample }
    end
  end
end
