# A contract is a ...
# recruitment_target:
# output_payment_percentage:
class Contract < ApplicationRecord
  belongs_to :statement
  belongs_to :course
  belongs_to :cohort
  belongs_to :lead_provider

  validates :statement_id, presence: true
  validates :course_id, presence: true
  validates :cohort_id, presence: true
  validates :lead_provider_id, presence: true

  validates :per_participant, numericality: { greater_than: 0 }
  validates :recruitment_target, numericality: { only_integer: true, greater_than: 0 }
  validates :output_payment_percentage, numericality: { only_integer: true, greater_than: 0, less_than: 100 }

  # these three fields should be null after [a certain date]
  validates :number_of_payment_periods, numericality: { only_integer: true, greater_than: 0 }
  validates :service_fee_percentage, numericality: { only_integer: true, greater_than: 0 }
  validates :service_fee_installments, numericality: { only_integer: true, greater_than: 0 }
end
