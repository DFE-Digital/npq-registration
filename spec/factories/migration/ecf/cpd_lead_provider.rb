# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_cpd_lead_provider, class: "Migration::Ecf::CpdLeadProvider" do
    name  { Faker::Company.name }
  end
end
