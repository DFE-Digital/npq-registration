require "rails_helper"

RSpec.describe DeliveryPartner, type: :model do
  describe "attributes" do
    subject { described_class.create(name: "new partner") }

    let(:uuid_format) { /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/ }

    it { is_expected.to have_attributes ecf_id: uuid_format }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :name }

    describe "uniqueness" do
      before { create :delivery_partner }

      it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    end
  end
end
