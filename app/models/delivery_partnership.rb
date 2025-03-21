class DeliveryPartnership < ApplicationRecord
  belongs_to :delivery_partner
  belongs_to :lead_provider
  belongs_to :cohort

  validates :delivery_partner_id, presence: true
  validates :lead_provider_id, presence: true
  validates :cohort_id, presence: true
  validates :delivery_partner_id, uniqueness: { scope: %i[lead_provider_id cohort_id] }
end
