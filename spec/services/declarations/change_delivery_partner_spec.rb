require "rails_helper"

RSpec.describe Declarations::ChangeDeliveryPartner, type: :model do
  let(:lead_provider) { LeadProvider.first }
  let(:cohort) { create(:cohort, :current) }

  let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
  let(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
  let(:new_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
  let(:new_secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
  let(:delivery_partner_id) { new_delivery_partner.ecf_id }
  let(:secondary_delivery_partner_id) { new_secondary_delivery_partner.ecf_id }

  let(:declaration) do
    create(:declaration,
           lead_provider:,
           delivery_partner:,
           secondary_delivery_partner:)
  end

  let(:instance) { described_class.new(declaration:, delivery_partner_id:, secondary_delivery_partner_id:) }

  describe "#change_delivery_partner" do
    subject(:change_delivery_partner) { instance.change_delivery_partner }

    it { is_expected.to be_truthy }

    it "reloads declaration after action" do
      allow(instance.declaration).to receive(:reload)
      change_delivery_partner
      expect(instance.declaration).to have_received(:reload)
    end

    context "when operation is performed" do
      before { change_delivery_partner }

      it "changes delivery partner" do
        expect(declaration.delivery_partner).to eq(new_delivery_partner)
      end

      it "changes secondary delivery partner" do
        expect(declaration.secondary_delivery_partner).to eq(new_secondary_delivery_partner)
      end

      context "when secondary delivery partner needs to be removed" do
        let(:secondary_delivery_partner_id) { nil }

        before { change_delivery_partner }

        it "is performed correctly" do
          expect(declaration.secondary_delivery_partner).to be_nil
        end
      end
    end
  end

  describe "validations" do
    subject { instance }

    before { instance.change_delivery_partner }

    it { is_expected.to validate_presence_of(:declaration) }

    context "when the delivery partner id is empty" do
      let(:delivery_partner_id) { nil }

      it { is_expected.to have_error(:delivery_partner_id, :blank, "The property '#/delivery_partner_id' must be present") }
    end

    context "when the delivery partner id is not found" do
      let(:delivery_partner_id) { "9e5822b2-ff83-4c42-8938-b762261bff65" }
      let(:secondary_delivery_partner_id) { nil }

      it { is_expected.to have_error(:delivery_partner, :presence, "The entered '#/delivery_partner_id' is not from your list of confirmed Delivery Partners for the Cohort") }
    end

    context "when the secondary delivery partner is not found" do
      let(:secondary_delivery_partner_id) { "9e5822b2-ff83-4c42-8938-b762261bff65" }

      it { is_expected.to have_error(:secondary_delivery_partner, :presence, "The entered '#/secondary_delivery_partner_id' is not from your list of confirmed Delivery Partners for the Cohort") }
    end

    context "when the delivery partner is not on the available partners list" do
      let(:delivery_partner_id) { create(:delivery_partner).ecf_id }

      it { is_expected.to have_error(:delivery_partner_id, :inclusion, "The entered '#/delivery_partner_id' is not from your list of confirmed Delivery Partners for the Cohort") }
    end

    context "when the secondary delivery partner is not on the available partners list" do
      let(:secondary_delivery_partner_id) { create(:delivery_partner).ecf_id }

      it { is_expected.to have_error(:secondary_delivery_partner_id, :inclusion, "The entered '#/secondary_delivery_partner_id' is not from your list of confirmed Delivery Partners for the Cohort") }
    end

    context "with the declarations_require_delivery_partner feature flag enabled" do
      before { allow(Feature).to receive(:declarations_require_delivery_partner?).and_return(true) }

      it { is_expected.to validate_presence_of(:delivery_partner_id).with_message("The property '#/delivery_partner_id' must be present") }
      it { is_expected.not_to validate_presence_of(:secondary_delivery_partner_id) }
    end

    context "when delivery_partner is blank but secondary_delivery_partner is not" do
      let(:delivery_partner_id) { nil }

      let(:delivery_partner) { nil }
      let(:secondary_delivery_partner) { nil }

      it { is_expected.to have_error(:secondary_delivery_partner_id, :present, "The property '#/secondary_delivery_partner_id' cannot be specified without the property '#/delivery_partner_id'") }
    end

    context "when delivery_partner and secondary_delivery partner are the same" do
      let(:secondary_delivery_partner_id) { delivery_partner_id }

      it { is_expected.to have_error(:secondary_delivery_partner_id, :duplicate_delivery_partner, "The property '#/secondary_delivery_partner_id' cannot have the same value as the property '#/delivery_partner_id'") }
    end
  end
end
