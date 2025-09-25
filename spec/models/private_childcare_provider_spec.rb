require "rails_helper"

RSpec.describe PrivateChildcareProvider, type: :model do
  it_behaves_like "a disableable model"

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
        expect(provider.registration_details).to eq("#{provider.urn} – #{provider.region}")
      end
    end

    context "without redacted info" do
      let(:provider) { build(:private_childcare_provider) }

      it "displays only the urn and name" do
        expect(provider.registration_details).to eq("#{provider.urn} – #{provider.name} – #{provider.address_string}")
      end
    end
  end

  describe "#eyl_disadvantaged?" do
    subject { provider.eyl_disadvantaged? }

    let(:provider) { build(:private_childcare_provider, provider_urn:) }

    context "when the provider is in the EY_OFSTED_URN_HASH" do
      let(:provider_urn) { "150014" } # URN taken from data file

      it { is_expected.to be true }
    end

    context "when the URN is not in the EY_OFSTED_URN_HASH" do
      let(:provider_urn) { "100001" }

      it { is_expected.to be false }

      context "when the URN is in the disadvantaged_early_years_school eligibility list" do
        before { create(:eligibility_list, :disadvantaged_early_years_school, identifier: provider_urn) }

        it { is_expected.to be true }
      end
    end
  end

  describe "#on_childminders_list?" do
    subject { provider.on_childminders_list? }

    let(:provider) { build(:private_childcare_provider, provider_urn:) }

    context "when the provider is in the CHILDMINDERS_OFSTED_URN_HASH" do
      let(:provider_urn) { "CA000006" } # URN taken from data file

      it { is_expected.to be true }
    end

    context "when the URN is not in the CHILDMINDERS_OFSTED_URN_HASH" do
      let(:provider_urn) { "100001" }

      it { is_expected.to be false }

      context "when the URN is in the disadvantaged_early_years_school eligibility list" do
        before { create(:eligibility_list, :childminder, identifier: provider_urn) }

        it { is_expected.to be true }
      end
    end
  end
end
