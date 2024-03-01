# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_lead_provider, class: "Migration::Ecf::NpqLeadProvider" do
    cpd_lead_provider { create(:ecf_migration_cpd_lead_provider) }

    sequence(:name) { |n| "NPQ Lead Provider #{n}" }
  end
end
