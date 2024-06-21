class Declaration < ApplicationRecord
  BILLABLE_STATES = %w[eligible payable paid].freeze
  CHANGEABLE_STATES = %w[eligible submitted].freeze

  belongs_to :application
  belongs_to :cohort
  belongs_to :lead_provider
  belongs_to :superseded_by, class_name: "Declaration", optional: true
  has_many :outcomes, dependent: :destroy
  has_many :statement_items

  UPLIFT_PAID_STATES = %w[paid awaiting_clawback clawed_back].freeze
  COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT = %w[npq-additional-support-offer npq-early-headship-coaching-offer].freeze
  ELIGIBLE_FOR_PAYMENT_STATES = %w[payable eligible].freeze

  delegate :course, :user, to: :application
  delegate :identifier, to: :course, prefix: true
  delegate :name, to: :lead_provider, prefix: true

  scope :billable, -> { where(state: BILLABLE_STATES) }
  scope :changeable, -> { where(state: CHANGEABLE_STATES) }
  scope :billable_or_changeable, -> { billable.or(changeable) }

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

  def billable_statement
    statement_items.find(&:billable?)&.statement
  end

  def refundable_statement
    statement_items.find(&:refundable?)&.statement
  end

  def uplift_paid?
    applicable_course = !application.course.identifier.in?(COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT)
    applicable_state = state.in?(UPLIFT_PAID_STATES)

    applicable_course && applicable_state && started_declaration_type? && application.targeted_delivery_funding_eligibility?
  end

  def eligible_for_payment?
    state.in?(ELIGIBLE_FOR_PAYMENT_STATES)
  end

  def ineligible_for_funding_reason
    return unless ineligible_state?

    case state_reason
    when "duplicate"
      "duplicate_declaration"
    else
      reason
    end
  end
end
