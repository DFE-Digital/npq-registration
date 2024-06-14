class Declaration < ApplicationRecord
  belongs_to :application
  belongs_to :cohort
  belongs_to :lead_provider
  belongs_to :superseded_by, class_name: "Declaration", optional: true

  enum state: {
    submitted: "submitted",
    eligible: "eligible",
    payable: "payable",
    paid: "paid",
    voided: "voided",
    ineligible: "ineligible",
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back",
  }, _suffix: true

  enum declaration_type: {
    started: "started",
    "retained-1": "retained-1",
    "retained-2": "retained-2",
    completed: "completed",
  }, _suffix: true

  enum state_reason: {
    duplicate: "duplicate",
  }, _suffix: true

  validates :declaration_date, :declaration_type, presence: true
end
