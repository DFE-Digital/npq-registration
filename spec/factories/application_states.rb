# frozen_string_literal: true

FactoryBot.define do
  factory :application_state do
    application
    lead_provider { LeadProvider.first }
    state { "active" }

    trait :withdrawn do
      state { ApplicationState.states[:withdrawn] }
      reason { "other" }
    end

    trait :deferred do
      state { ApplicationState.states[:deferred] }
      reason { "other" }
    end
  end
end
