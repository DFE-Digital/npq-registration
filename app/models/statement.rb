class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider
  has_many :statement_items

  validates :output_fee, presence: true
  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2050, only_integer: true }

  validate :validate_max_statement_items_count

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
