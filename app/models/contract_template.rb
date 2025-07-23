class ContractTemplate < ApplicationRecord
  has_paper_trail

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
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  def new_from_existing(attributes_to_override)
    new_attributes = {
      special_course: special_course,
      per_participant: per_participant,
      output_payment_percentage: output_payment_percentage,
      number_of_payment_periods: number_of_payment_periods,
      service_fee_percentage: service_fee_percentage,
      service_fee_installments: service_fee_installments,
      recruitment_target: recruitment_target,
      monthly_service_fee: monthly_service_fee,
      targeted_delivery_funding_per_participant: targeted_delivery_funding_per_participant,
    }.merge(attributes_to_override)

    ContractTemplate.new(new_attributes)
  end

  def find_from_existing(attributes_to_override)
    ContractTemplate.where(
      special_course: special_course,
      per_participant: attributes_to_override[:per_participant],
      output_payment_percentage: output_payment_percentage,
      number_of_payment_periods: number_of_payment_periods,
      service_fee_percentage: service_fee_percentage,
      service_fee_installments: service_fee_installments,
      recruitment_target: recruitment_target,
      monthly_service_fee: monthly_service_fee,
      targeted_delivery_funding_per_participant: targeted_delivery_funding_per_participant,
    ).first
  end
end
