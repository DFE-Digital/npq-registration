require "rails_helper"

RSpec.describe AdminService::DeliveryPartnersSearch do
  subject { described_class.new(q:) }

  let!(:a_delivery_partner) { create(:delivery_partner, name: "Alpha Partner") }
  let!(:delivery_partner) { create(:delivery_partner) }
  let!(:z_delivery_partner) { create(:delivery_partner, name: "Zeta Partner") }

  describe "#call" do
    context "when partial name match with different capitalisation" do
      let(:q) { delivery_partner.name.first(3).upcase }

      it "returns the match" do
        expect(subject.call).to include(delivery_partner)
      end
    end

    context "when no match" do
      let(:q) { "NonExistent" }

      it "returns an empty array" do
        expect(subject.call).to be_empty
      end
    end

    context "when no query provided" do
      let(:q) { nil }

      it "returns results ordered by name" do
        expect(subject.call).to eq([a_delivery_partner, delivery_partner, z_delivery_partner])
      end
    end

    context "with a matching ECF ID" do
      let(:q) { delivery_partner.ecf_id }

      it "returns the match" do
        expect(subject.call).to include(delivery_partner)
      end
    end

    context "with a random ECF ID" do
      let(:q) { SecureRandom.uuid }

      it "does not return a match" do
        expect(subject.call).to be_empty
      end
    end

    context "with an ECF ID without hyphens" do
      let(:q) { delivery_partner.ecf_id.gsub(/-/, '') }

      it "returns the match" do
        expect(subject.call).to include(delivery_partner)
      end
    end

    context "with an uppercase ECF ID" do
      let(:q) { delivery_partner.ecf_id.upcase }

      it "returns the match" do
        expect(subject.call).to include(delivery_partner)
      end
    end

    context "with an uppercase ECF ID without hyphens" do
      let(:q) { delivery_partner.ecf_id.upcase.gsub(/-/, '') }

      it "returns the match" do
        expect(subject.call).to include(delivery_partner)
      end
    end
  end
end
