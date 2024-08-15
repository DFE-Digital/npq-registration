# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  enum state: {
    active: "active",
    deferred: "deferred",
    withdrawn: "withdrawn",
  }, _suffix: true

  scope :most_recent, -> { order("created_at desc").limit(1) }
  scope :for_lead_provider, ->(lead_provider) { where(lead_provider:) }
end
