class StatementItem < ApplicationRecord
  BILLABLE_STATES = %w[eligible payable paid].freeze
  REFUNDABLE_STATES = %w[awaiting_clawback clawed_back].freeze

  belongs_to :statement
  # belongs_to :declaration
  has_many :events, dependent: :nullify

  scope :billable, -> { where(state: BILLABLE_STATES) }
  scope :refundable, -> { where(state: REFUNDABLE_STATES) }

  state_machine :state, initial: :eligible do
    state :eligible
    state :payable
    state :paid
    state :voided
    state :ineligible
    state :awaiting_clawback
    state :clawed_back

    event :mark_payable do
      transition [:eligible] => :payable
    end

    event :mark_paid do
      transition [:payable] => :paid
    end

    event :mark_voided do
      transition %i[eligible payable] => :voided
    end

    event :mark_awaiting_clawback do
      transition [:paid] => :awaiting_clawback
    end

    event :mark_clawed_back do
      transition [:awaiting_clawback] => :clawed_back
    end

    event :mark_ineligible do
      transition [:eligible] => :ineligible
    end
  end

  def billable?
    BILLABLE_STATES.include?(state)
  end

  def refundable?
    REFUNDABLE_STATES.include?(state)
  end
end
