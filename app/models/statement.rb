class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider
  has_many :statement_items

  validates :output_fee, inclusion: [true, false]
  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2050, only_integer: true }
  validates :ecf_id, presence: true, uniqueness: { case_sensitive: false }

  validate :validate_max_statement_items_count

  scope :unpaid, -> { where(state: %w[open payable]) }
  scope :paid, -> { where(state: "paid") }
  scope :with_output_fee, -> { where(output_fee: true) }

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
      errors.add(:statement_items, "cannot have more than two items")
    end
  end
end
