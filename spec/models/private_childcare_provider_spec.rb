require "rails_helper"

RSpec.describe PrivateChildcareProvider, type: :model do
  describe "#on_early_years_register?" do
    let(:provider) do
      described_class.new(early_years_individual_registers:)
    end

    context "when the provider is on the early year register" do
      let(:early_years_individual_registers) { %w[CCR VCR EYR] }

      it "returns true" do
        expect(provider.on_early_years_register?).to be true
      end
    end

    context "when the provider is not on the early year register" do
      let(:early_years_individual_registers) { %w[CCR VCR] }

      it "returns false" do
        expect(provider.on_early_years_register?).to be false
      end
    end
  end

  describe "#registration_details" do
    context "with redacted info" do
      let(:provider) { build(:private_childcare_provider, :redacted) }

      it "displays only the urn and the region" do
        expect(provider.registration_details).to eq("#{provider.urn} - #{provider.region}")
      end
    end

    context "without redacted info" do
      let(:provider) { build(:private_childcare_provider) }

      it "displays only the urn and name" do
        expect(provider.registration_details).to eq("#{provider.urn} - #{provider.name} - #{provider.address_string}")
      end
    end
  end
end
