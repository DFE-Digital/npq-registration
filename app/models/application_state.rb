# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  LOOKUP_REASON_TIME_VARIANCE_SECONDS = 0.5

  belongs_to :application
  belongs_to :lead_provider, optional: true

  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  enum :state, {
    active: "active",
    deferred: "deferred",
    withdrawn: "withdrawn",
  }, suffix: true

  scope :most_recent, -> { order("created_at desc").limit(1) }
  scope :for_lead_provider, ->(lead_provider) { where(lead_provider:) }

  def self.lookup_reason(application:, created_at:, state:)
    time_range = (created_at - LOOKUP_REASON_TIME_VARIANCE_SECONDS)..(created_at + LOOKUP_REASON_TIME_VARIANCE_SECONDS)
    order(id: :desc).find_by(application:, created_at: time_range, state:)&.reason
  end
end
