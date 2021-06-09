require "rails_helper"

RSpec.describe Forms::DeliveryPartner, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:delivery_partner_knowledge) }
    it { is_expected.to validate_inclusion_of(:delivery_partner_knowledge).in_array(Forms::DeliveryPartner::VALID_DELIVERY_PARTNER_KNOWLEDGE_OPTIONS) }
  end
end
