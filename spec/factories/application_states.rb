# frozen_string_literal: true

FactoryBot.define do
  factory :application_state do
    application
    lead_provider { LeadProvider.all.sample }
  end
end
