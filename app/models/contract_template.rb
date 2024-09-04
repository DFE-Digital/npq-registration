class ContractTemplate < ApplicationRecord
  has_many :contracts

  validates :number_of_payment_periods,
            :output_payment_percentage,
            :service_fee_installments,
            :service_fee_percentage,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }
  validates :per_participant,
            numericality: {
              greater_than: 0.0,
            }
  validates :recruitment_target,
            numericality: {
              only_integer: true,
              greater_than: 0,
            }
end
