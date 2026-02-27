module Declarations
  class ChangeDeliveryPartner
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declaration
    attribute :delivery_partner_id
    attribute :secondary_delivery_partner_id
    validate :delivery_partner_existence
    validate :secondary_delivery_partner_existence

    validates :declaration, presence: true, validate_and_copy_errors: true
    validates :delivery_partner_id, presence: true

    def change_delivery_partner
      declaration.delivery_partner = delivery_partner
      declaration.secondary_delivery_partner = secondary_delivery_partner

      return false unless valid?

      declaration.save!
      declaration.reload
    end

  private

    def delivery_partner_existence
      if delivery_partner.nil?
        errors.add(:delivery_partner, :presence)
      end
    end

    def secondary_delivery_partner_existence
      if secondary_delivery_partner_id.present? && secondary_delivery_partner.nil?
        errors.add(:secondary_delivery_partner, :presence)
      end
    end

    def delivery_partner
      DeliveryPartner.find_by(ecf_id: delivery_partner_id)
    end

    def secondary_delivery_partner
      DeliveryPartner.find_by(ecf_id: secondary_delivery_partner_id)
    end
  end
end
