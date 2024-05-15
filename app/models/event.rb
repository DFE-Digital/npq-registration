class Event < ApplicationRecord
  EVENT_TYPES = %w[ApplicationAcceptance].freeze

  validates :title,
            presence: { message: "Enter a title" },
            length: { maximum: 256, message: "Title must be shorter than 256 characters" }

  validates :event_type,
            inclusion: { in: EVENT_TYPES, message: "Event type must be in the list of valid event types" }

  belongs_to :admin, optional: true
  belongs_to :application, optional: true
  belongs_to :cohort, optional: true
  belongs_to :course, optional: true
  belongs_to :lead_provider, optional: true
  belongs_to :private_childcare_provider, optional: true
  belongs_to :school, optional: true
  belongs_to :statement, optional: true
  belongs_to :statement_item, optional: true
  belongs_to :user, optional: true
end
