# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  belongs_to :application
  belongs_to :lead_provider, optional: true

  enum state: {
    active: "active",
    deferred: "deferred",
    withdrawn: "withdrawn",
  }
end
