class DeliveryPartner < ApplicationRecord
  has_many :delivery_partnerships
  has_many :lead_providers, through: :delivery_partnerships
  has_many :cohorts, through: :delivery_partnerships

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def declarations
    Declaration.for_delivery_partners(self)
  end
end
