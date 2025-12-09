class Contract < ApplicationRecord
  has_paper_trail

  belongs_to :statement
  belongs_to :course
  belongs_to :contract_template

  delegate :monthly_service_fee,
           :number_of_payment_periods,
           :output_payment_percentage,
           :per_participant,
           :recruitment_target,
           :service_fee_installments,
           :service_fee_percentage,
           :targeted_delivery_funding_per_participant,
           to: :contract_template

  validates :course_id, uniqueness: { scope: :statement_id }
  validate :changing_contract_template_when_payable
  validate :changing_contract_template_when_paid

  before_destroy :check_statement_payable
  before_destroy :check_statement_paid

private

  def changing_contract_template_when_payable
    return unless statement&.payable?

    errors.add(:contract_template, :statement_payable) if contract_template_id_changed?
  end

  def changing_contract_template_when_paid
    return unless statement&.paid?

    errors.add(:contract_template, :statement_paid) if contract_template_id_changed?
  end

  def check_statement_payable
    if statement&.payable?
      errors.add(:base, :deleting_when_statement_payable)
      throw :abort
    end
  end

  def check_statement_paid
    if statement&.paid?
      errors.add(:base, :deleting_when_statement_paid)
      throw :abort
    end
  end
end
