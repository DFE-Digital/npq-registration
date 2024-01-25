# A contract is a ...
# recruitment_target:
# output_payment_percentage:
class Contract < ApplicationRecord
  belongs_to :statement
  belongs_to :course

  validates \
    :special_course,
    :per_participant,
    :recruitment_target,
    :output_payment_percentage,
    :service_fee_installments,
    :number_of_payment_periods,
    :service_fee_percentage, presence: true

  validates :per_participant, numericality: { greater_than: 0 }
  validates :recruitment_target, numericality: { only_integer: true, greater_than: 0 }
  validates :output_payment_percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 100 }

  # these three fields should be null after [a certain date]
  validates :number_of_payment_periods, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :service_fee_percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :service_fee_installments, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  delegate :cohort, :lead_provider,
    to: :statement

end
