require "rails_helper"

RSpec.describe DeliveryPartner, type: :model do
  describe "attributes" do
    subject { described_class.create(name: "new partner") }

    let(:uuid_format) { /\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/ }

    it { is_expected.to have_attributes ecf_id: uuid_format }
  end

  describe "relationships" do
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:lead_providers).through(:delivery_partnerships) }
    it { is_expected.to have_many(:cohorts).through(:delivery_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :name }

    describe "uniqueness" do
      before { create :delivery_partner }

      it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    end
  end

  describe "#declarations" do
    subject { delivery_partner.declarations }

    let(:delivery_partner) { create :delivery_partner }
    let(:lead_provider) { create :lead_provider, delivery_partner: }
    let(:declaration_as_primary) { create :declaration, lead_provider:, delivery_partner: }

    it { is_expected.to include declaration_as_primary }

    context "when declared as secondary partner" do
      let(:another_partner) { create :delivery_partner, lead_provider: }

      let :declaration_as_secondary do
        create :declaration, lead_provider:,
                             delivery_partner: another_partner,
                             secondary_delivery_partner: delivery_partner
      end

      it { is_expected.to include declaration_as_secondary }
    end
  end

  describe "#cohorts_for_lead_provider" do
    subject { delivery_partner.cohorts_for_lead_provider(lead_provider) }

    let(:delivery_partner) { create :delivery_partner, lead_providers: { cohort => lead_provider, other_cohort => other_lead_provider } }
    let(:lead_provider) { create :lead_provider }
    let(:other_lead_provider) { create :lead_provider }
    let(:cohort) { create :cohort }
    let(:other_cohort) { create :cohort }

    before do
      create :delivery_partner, lead_providers: { cohort => lead_provider, other_cohort => other_lead_provider }
    end

    it { is_expected.to eq [cohort] }
  end
end
