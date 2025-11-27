class Statement < ApplicationRecord
  has_paper_trail meta: { note: :version_note }
  attr_accessor :version_note

  belongs_to :cohort
  belongs_to :lead_provider
  has_many :statement_items
  has_many :contracts
  has_many :declarations, through: :statement_items
  has_many :adjustments
  has_many :milestone_statements
  has_many :milestones, through: :milestone_statements

  validates :output_fee, inclusion: { in: [true, false] }
  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2050, only_integer: true }
  validates :lead_provider_id, uniqueness: { scope: %i[cohort_id year month] }
  validates :ecf_id, uniqueness: { case_sensitive: false }

  validate :payment_date_on_or_after_deadline_date
  validate :no_milestones_associated, if: :output_fee_changed?
  validate :changing_attributes_when_payable, on: :update
  validate :changing_attributes_when_paid, on: :update

  scope :with_output_fee, ->(output_fee: true) { where(output_fee:) }
  scope :with_state, ->(*state) { where(state:) }
  scope :unpaid, -> { with_state(%w[open payable]) }
  scope :paid, -> { with_state("paid") }
  scope :next_output_fee_statements, -> { with_state("open").with_output_fee.order(:deadline_date).where("deadline_date >= ?", Date.current) }

  state_machine :state, initial: :open do
    state :open
    state :payable
    state :paid

    event :mark_payable do
      transition [:open] => :payable
    end

    event :mark_paid do
      transition [:payable] => :paid
    end
  end

  def mark_as_paid_at!
    update!(marked_as_paid_at: Time.zone.now)
  end

  def marked_as_paid_with_date?
    marked_as_paid_at.present? && paid?
  end

  def allow_marking_as_paid?
    output_fee &&
      payable? &&
      !!deadline_date&.past? &&
      !marked_as_paid_at? &&
      declarations.any?
  end

  def authorising_for_payment?
    payable? && marked_as_paid_at?
  end

  def use_targeted_delivery_funding?
    Date.new(year, month) <= Date.new(2025, 10) && cohort.start_year >= 2022
  end

  def past?
    Date.new(year, month) < Date.current.beginning_of_month
  end

private

  def payment_date_on_or_after_deadline_date
    return unless deadline_date && payment_date
    return unless payment_date < deadline_date

    errors.add :payment_date, :invalid
  end

  def no_milestones_associated
    return unless milestone_statements.exists?

    errors.add :output_fee, :has_milestones
  end

  def changing_attributes_when_payable
    return if errors.any?

    allowed_to_change = %w[output_fee state]
    errors.add :base, :statement_payable if state_was == "payable" && (changed - allowed_to_change).any?
  end

  def changing_attributes_when_paid
    return if errors.any?

    errors.add :base, :statement_paid if state_was == "paid" && changed.any?
  end
end
