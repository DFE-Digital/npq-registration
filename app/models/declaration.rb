class Declaration < ApplicationRecord
  BILLABLE_STATES = %w[eligible payable paid].freeze
  CHANGEABLE_STATES = %w[eligible submitted].freeze
  UPLIFT_PAID_STATES = %w[paid awaiting_clawback clawed_back].freeze
  COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT = %w[npq-additional-support-offer npq-early-headship-coaching-offer].freeze
  ELIGIBLE_FOR_PAYMENT_STATES = %w[payable eligible].freeze
  VOIDABLE_STATES = %w[submitted eligible payable ineligible].freeze

  belongs_to :application
  belongs_to :cohort
  belongs_to :lead_provider
  belongs_to :superseded_by, class_name: "Declaration", optional: true
  has_many :participant_outcomes, dependent: :destroy
  has_many :statement_items
  has_many :statements, through: :statement_items

  delegate :course, :user, to: :application
  delegate :identifier, to: :course, prefix: true
  delegate :name, to: :lead_provider, prefix: true

  scope :billable, -> { where(state: BILLABLE_STATES) }
  scope :changeable, -> { where(state: CHANGEABLE_STATES) }
  scope :billable_or_changeable, -> { billable.or(changeable) }
  scope :voidable, -> { where(state: VOIDABLE_STATES) }
  scope :billable_or_voidable, -> { billable.or(voidable) }
  scope :with_lead_provider, ->(lead_provider) { where(lead_provider:) }
  scope :completed, -> { where(declaration_type: "completed") }
  scope :with_course_identifier, ->(course_identifier) { joins(application: :course).where(course: { identifier: course_identifier }) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :eligible_for_outcomes, lambda { |lead_provider, course_identifier|
    completed
    .with_lead_provider(lead_provider)
    .with_course_identifier(course_identifier)
    .billable_or_voidable
    .latest_first
  }

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

  state_machine :state, initial: :submitted do
    event :mark_eligible do
      transition [:submitted] => :eligible
    end

    event :mark_payable do
      transition [:eligible] => :payable
    end

    event :mark_paid do
      transition [:payable] => :paid
    end

    event :mark_ineligible do
      transition %i[submitted eligible payable paid] => :ineligible
    end

    event :mark_awaiting_clawback do
      transition %i[paid] => :awaiting_clawback
    end

    event :mark_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end

    event :mark_voided do
      transition %i[submitted eligible payable ineligible] => :voided
    end
  end

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
  validate :validate_declaration_date_within_schedule
  validate :validate_declaration_date_not_in_the_future

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

  def voidable?
    state.in?(VOIDABLE_STATES)
  end

  def ineligible_for_funding_reason
    return unless ineligible_state?

    case state_reason
    when "duplicate"
      "duplicate_declaration"
    else
      state_reason
    end
  end

  def duplicate_declarations
    self
      .class
      .billable_or_changeable
      .joins(application: %i[user course])
      .where(user: { trn: application.user.trn })
      .where.not(user: { trn: nil })
      .where.not(user: { id: application.user_id })
      .where.not(id:)
      .where(
        declaration_type:,
        superseded_by_id: nil,
        application: { course: application.course.rebranded_alternative_courses },
      )
  end

private

  def validate_declaration_date_within_schedule
    return unless application&.schedule
    return unless declaration_date

    if declaration_date < application.schedule.applies_from
      errors.add(:declaration_date, :declaration_before_schedule_start)
    end
  end

  def validate_declaration_date_not_in_the_future
    errors.add(:declaration_date, :future_declaration_date) if declaration_date&.future?
  end
end
