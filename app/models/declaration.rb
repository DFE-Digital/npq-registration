class Declaration < ApplicationRecord
  BILLABLE_STATES = %w[eligible payable paid].freeze
  CHANGEABLE_STATES = %w[eligible submitted].freeze
  UPLIFT_PAID_STATES = %w[paid awaiting_clawback clawed_back].freeze
  COURSE_IDENTIFIERS_INELIGIBLE_FOR_UPLIFT = %w[npq-additional-support-offer npq-early-headship-coaching-offer].freeze
  VOIDABLE_STATES = %w[submitted eligible payable ineligible].freeze
  DELIVER_PARTNER_REQUIRED_FROM = 2024

  has_paper_trail ignore: [:updated_at]

  belongs_to :application
  belongs_to :cohort
  belongs_to :lead_provider
  belongs_to :superseded_by, class_name: "Declaration", optional: true
  belongs_to :delivery_partner, optional: true
  belongs_to :secondary_delivery_partner, class_name: "DeliveryPartner", optional: true
  has_many :participant_outcomes, dependent: :destroy
  has_many :statement_items
  has_many :statements, through: :statement_items

  delegate :course, :user, to: :application
  delegate :inside_catchment?, to: :application, prefix: true, allow_nil: true
  delegate :identifier, to: :course, prefix: true
  delegate :name, to: :lead_provider, prefix: true

  scope :billable, -> { where(state: BILLABLE_STATES) }
  scope :changeable, -> { where(state: CHANGEABLE_STATES) }
  scope :billable_or_changeable, -> { billable.or(changeable) }
  scope :voidable, -> { where(state: VOIDABLE_STATES) }
  scope :billable_or_voidable, -> { billable.or(voidable) }
  scope :awaiting_clawback, -> { where(state: :awaiting_clawback) }
  scope :with_lead_provider, ->(lead_provider) { where(lead_provider:) }
  scope :completed, -> { where(declaration_type: "completed") }
  scope :with_course_identifier, ->(course_identifier) { joins(application: :course).where(course: { identifier: course_identifier }) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  scope :eligible_for_outcomes, lambda { |lead_provider, course_identifier|
    completed
    .with_lead_provider(lead_provider)
    .with_course_identifier(course_identifier)
    .billable_or_voidable
    .latest_first
  }

  enum :state, {
    submitted: "submitted",
    eligible: "eligible",
    payable: "payable",
    paid: "paid",
    voided: "voided",
    ineligible: "ineligible",
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back",
  }, suffix: true

  state_machine :state, initial: :submitted do
    event :mark_eligible do
      transition %i[submitted] => :eligible
    end

    event :mark_payable do
      transition %i[eligible] => :payable
    end

    event :mark_paid do
      transition %i[payable] => :paid
    end

    event :mark_ineligible do
      transition %i[submitted] => :ineligible
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

    event :revert_to_eligible do
      transition %i[payable] => :eligible
    end
  end

  enum :declaration_type, {
    started: "started",
    "retained-1": "retained-1",
    "retained-2": "retained-2",
    completed: "completed",
  }, suffix: true, validate: true

  enum :state_reason, {
    duplicate: "duplicate",
  }, suffix: true

  validates :declaration_date, :declaration_type, presence: true
  validate :validate_declaration_date_within_schedule
  validate :validate_declaration_date_not_in_the_future
  validates :ecf_id, uniqueness: { case_sensitive: false }
  validate :validate_max_statement_items_count

  validates :delivery_partner_id, presence: true, if: :delivery_partner_required
  validates :delivery_partner_id, absence: { message: :overseas },
                                  unless: :application_inside_catchment?
  validates :delivery_partner_id, inclusion: { in: :available_delivery_partner_ids },
                                  if: -> { delivery_partner && delivery_partner_changed? }

  validates :secondary_delivery_partner_id, absence: true, unless: :delivery_partner

  validates :secondary_delivery_partner_id,
            absence: { message: :overseas },
            if: -> { delivery_partner_id && !application_inside_catchment? }

  validates :secondary_delivery_partner_id,
            inclusion: { in: :available_delivery_partner_ids },
            if: -> { secondary_delivery_partner && secondary_delivery_partner_changed? }

  validate :delivery_partners_are_not_the_same, if: :delivery_partner

  scope :for_delivery_partners, lambda { |delivery_partner|
    where(delivery_partner: delivery_partner)
      .or(where(secondary_delivery_partner: delivery_partner))
  }

  def self.order_by_milestones
    scope = order(Arel.sql(<<~SQL))
      CASE declaration_type
        WHEN 'completed' THEN 1
        WHEN 'retained-2' THEN 2
        WHEN 'retained-1' THEN 3
        WHEN 'started' THEN 4
      END
    SQL
    scope.order(Arel.sql(<<~SQL))
      CASE state
        WHEN 'submitted' THEN 1
        WHEN 'eligible' THEN 1
        WHEN 'payable' THEN 1
        WHEN 'paid' THEN 1
        ELSE 2
      END
    SQL
  end

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
    can_mark_paid? || can_mark_payable?
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

  def available_delivery_partner_ids
    return [] unless lead_provider && cohort

    lead_provider.delivery_partners_for_cohort(cohort).map(&:id)
  end

  def delivery_partners
    [delivery_partner, secondary_delivery_partner].compact
  end

  def state_history
    changes = versions.where_attribute_changes(:state).order(created_at: :asc, id: :asc)

    if changes.none?
      [{ title: state.humanize, at: created_at }]
    else
      result = []
      result << { title: changes.first.object_changes.dig("state", 0).humanize, at: created_at } unless changes.first.created_at == created_at
      result += changes.map { |v| { title: v.object_changes.dig("state", 1).humanize, at: v.created_at } }
      result
    end
  end

private

  def validate_declaration_date_within_schedule
    return unless application&.schedule
    return unless declaration_date
    return if persisted? && !declaration_date_changed?

    if declaration_date < application.schedule.applies_from
      errors.add(:declaration_date, :declaration_before_schedule_start)
    end
  end

  def validate_declaration_date_not_in_the_future
    errors.add(:declaration_date, :future_declaration_date) if declaration_date&.future?
  end

  def validate_max_statement_items_count
    if statement_items.count > 2
      errors.add(:statement_items, :more_than_two_statement_items)
    end
  end

  def delivery_partners_are_not_the_same
    if delivery_partner == secondary_delivery_partner
      errors.add :secondary_delivery_partner_id, :duplicate_delivery_partner
    end
  end

  def delivery_partner_required
    return false unless cohort
    return false unless application_inside_catchment?
    return false if persisted? && !delivery_partner_id_changed?

    cohort.start_year >= DELIVER_PARTNER_REQUIRED_FROM
  end
end
