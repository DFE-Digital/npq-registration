require "rails_helper"

RSpec.describe Registration::Institution do
  subject :instance do
    described_class.new(identifier:, works_in_childcare:, works_in_school:)
  end

  let(:school) { create :school }
  let(:identifier) { "School-#{school.urn}" }
  let(:works_in_school) { true }
  let(:works_in_childcare) { true }

  describe ".fetch" do
    subject do
      described_class.fetch(identifier:, works_in_school:, works_in_childcare:)
    end

    it { is_expected.to eq school }
  end

  describe "#fetch" do
    subject { instance.fetch }

    context "without identifier" do
      let(:identifier) { nil }

      it { is_expected.to be_nil }
    end

    context "with partial identifier" do
      let(:identifier) { "School" }

      it { is_expected.to be_nil }
    end

    context "with unprefixed identifier" do
      let(:identifier) { school.urn }

      it { is_expected.to be_nil }
    end

    context "with School identifier" do
      context "when working in childcare" do
        let(:works_in_school) { false }

        it { is_expected.to eq school }
      end

      context "when working in school" do
        let(:works_in_childcare) { false }

        it { is_expected.to eq school }
      end

      context "when working in neither" do
        let(:works_in_school) { false }
        let(:works_in_childcare) { false }

        it { is_expected.to be_nil }
      end
    end

    context "with Childcare identifier" do
      let(:provider) { create :private_childcare_provider }
      let(:identifier) { "PrivateChildcareProvider-#{provider.provider_urn}" }

      context "when working in childcare" do
        let(:works_in_school) { false }

        it { is_expected.to eq provider }
      end

      context "when working in school" do
        let(:works_in_childcare) { false }

        it { is_expected.to be_nil }
      end

      context "when working in neither" do
        let(:works_in_school) { false }
        let(:works_in_childcare) { false }

        it { is_expected.to be_nil }
      end
    end

    context "with Local Authority identifier" do
      let(:authority) { create :local_authority }
      let(:identifier) { "LocalAuthority-#{authority.id}" }

      context "when working in childcare" do
        let(:works_in_school) { false }

        it { is_expected.to eq authority }
      end

      context "when working in school" do
        let(:works_in_childcare) { false }

        it { is_expected.to eq authority }
      end

      context "when working in neither" do
        let(:works_in_school) { false }
        let(:works_in_childcare) { false }

        it { is_expected.to be_nil }
      end
    end
  end
end
