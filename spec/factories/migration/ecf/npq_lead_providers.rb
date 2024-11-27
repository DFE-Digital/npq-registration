# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_lead_provider, class: "Migration::Ecf::NpqLeadProvider" do
    sequence(:name) { |n| "NPQ Lead Provider #{n}" }
  end
end
