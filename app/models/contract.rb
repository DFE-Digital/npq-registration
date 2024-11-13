class Contract < ApplicationRecord
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
end
