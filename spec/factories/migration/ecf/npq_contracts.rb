# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_contract, class: "Migration::Ecf::NpqContract" do
    npq_lead_provider { create(:ecf_migration_npq_lead_provider) }
    cohort { create(:ecf_migration_cohort) }
    course_identifier { create(:ecf_migration_npq_course).identifier }
    version { "0.0.1" }

    service_fee_percentage { 50 }
    output_payment_percentage { 70 }
    per_participant { 900.00 }
    number_of_payment_periods { 4 }
    recruitment_target { 82 }
    service_fee_installments { 29 }
    targeted_delivery_funding_per_participant { 200.0 }
    monthly_service_fee { 400.0 }
  end
end
