# frozen_string_literal: true

FactoryBot.define do
  factory :response_comparison, class: "Migration::ParityCheck::ResponseComparison" do
    lead_provider
    request_path { "/path" }
    request_method { "get" }
    ecf_response_time_ms { 100 }
    npq_response_time_ms { 50 }
    equal

    trait :equal do
      ecf_response_status_code { 200 }
      npq_response_status_code { 200 }
    end

    trait :different do
      ecf_response_status_code { 200 }
      npq_response_status_code { 200 }
      ecf_response_body { "response1" }
      npq_response_body { "response2" }
    end

    trait :unexpected do
      ecf_response_status_code { 500 }
      npq_response_status_code { 500 }
    end

    after :create do |response_comparison|
      create(:ecf_migration_npq_lead_provider, id: response_comparison.lead_provider.ecf_id) unless Migration::Ecf::NpqLeadProvider.exists?(response_comparison.lead_provider.ecf_id)
    end
  end
end
