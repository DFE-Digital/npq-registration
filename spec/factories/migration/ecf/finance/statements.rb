# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_statement, class: "Migration::Ecf::Finance::Statement" do
    name          { Time.zone.today.strftime "%B %Y" }
    deadline_date { (Time.zone.today - 1.month).end_of_month }
    payment_date  { Time.zone.today.end_of_month }
    cohort { create(:ecf_migration_cohort) }
    type { "Finance::Statement::NPQ" }
    contract_version { "1.0" }
    cpd_lead_provider_id { create(:ecf_migration_npq_lead_provider).cpd_lead_provider_id }
  end
end
