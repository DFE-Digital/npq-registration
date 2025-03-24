require "rails_helper"

RSpec.describe DeliveryPartnership, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to :delivery_partner }
    it { is_expected.to belong_to :lead_provider }
    it { is_expected.to belong_to :cohort }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :delivery_partner_id }
    it { is_expected.to validate_presence_of :lead_provider_id }
    it { is_expected.to validate_presence_of :cohort_id }

    describe "uniqueness" do
      subject { described_class.new }

      before { create :delivery_partnership }

      it "delivery partner must be unique for a given lead provider and cohort" do
        expect(subject).to validate_uniqueness_of(:delivery_partner_id).scoped_to(%i[lead_provider_id cohort_id])
      end
    end
  end
end
