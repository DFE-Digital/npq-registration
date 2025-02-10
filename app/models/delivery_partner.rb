class DeliveryPartner < ApplicationRecord
  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
