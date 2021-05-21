require "rails_helper"

RSpec.describe Forms::DeliveryPartner, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:delivery_partner_knowledge) }
  end
end
