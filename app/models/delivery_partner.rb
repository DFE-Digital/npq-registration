class DeliveryPartner < ApplicationRecord
  has_many :delivery_partnerships
  has_many :lead_providers, through: :delivery_partnerships
  has_many :cohorts, through: :delivery_partnerships

  accepts_nested_attributes_for :delivery_partnerships, allow_destroy: true

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def declarations
    Declaration.for_delivery_partners(self)
  end

  def cohorts_for_lead_provider(lead_provider)
    delivery_partnerships.select { |delivery_partnership| delivery_partnership.lead_provider_id == lead_provider.id }.map(&:cohort)
  end
end
