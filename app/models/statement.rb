class Statement < ApplicationRecord
  has_paper_trail meta: { note: :version_note }
  attr_accessor :version_note

  belongs_to :cohort
  belongs_to :lead_provider
  has_many :statement_items
  has_many :contracts
  has_many :declarations, through: :statement_items
  has_many :adjustments

  validates :output_fee, inclusion: { in: [true, false] }
  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2050, only_integer: true }
  validates :lead_provider_id, uniqueness: { scope: %i[cohort_id year month] }
  validates :ecf_id, uniqueness: { case_sensitive: false }

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

  def marked_as_paid?
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

  def show_targeted_delivery_funding?
    cohort.start_year >= 2022
  end

  def allow_adjustments?
    open?
  end
end
