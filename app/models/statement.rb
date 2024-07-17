class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider
  has_many :statement_items

  validates :output_fee,
            inclusion: {
              in: [true, false],
              message: "Choose yes or no for output fee",
            }

  validates :month,
            numericality: {
              in: 1..12,
              only_integer: true,
              message: "Month must be a number between 1 and 12",
            }
  validates :year,
            numericality: {
              in: 2020..2050,
              only_integer: true,
              message: "Year must be a 4 digit number",
            }
  validates :ecf_id,
            presence: { message: "Enter an ECF ID" },
            uniqueness: {
              case_sensitive: false,
              message: "ECF ID must be unique",
            }

  validate :validate_max_statement_items_count

  scope :with_output_fee, ->(output_fee: true) { where(output_fee:) }
  scope :with_state, ->(*state) { where(state:) }
  scope :unpaid, -> { with_state(%w[open payable]) }
  scope :paid, -> { with_state("paid") }
  scope :next_output_fee_statements, -> { with_output_fee.order(:deadline_date).where("deadline_date >= ?", Date.current) }

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

private

  def validate_max_statement_items_count
    if statement_items.count > 2
      errors.add(:statement_items, "There cannot be more than two items per statement")
    end
  end
end
